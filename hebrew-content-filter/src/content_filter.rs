use crate::html_parser::extract_text_from_html;
use crate::pattern_matcher::{MatchResult, PatternMatcher};
use std::collections::HashMap;

#[derive(Debug, Clone, PartialEq)]
pub enum FilterResult {
    Clean,
    Inappropriate { score: u32, matches: Vec<String> },
}

pub struct ContentFilter {
    matcher: PatternMatcher,
    threshold: u32,
}

impl ContentFilter {
    /// Create a new content filter with default inappropriate words list
    pub fn new() -> Self {
        Self::with_custom_words(Self::get_default_blacklist(), 10)
    }

    /// Create filter with custom word list and threshold
    pub fn with_custom_words(words: Vec<String>, threshold: u32) -> Self {
        Self {
            matcher: PatternMatcher::new(words),
            threshold,
        }
    }

    /// Get default blacklist (basic example - should be expanded in production)
    /// Note: These are example roots/patterns for demonstration
    fn get_default_blacklist() -> Vec<String> {
        vec![
            // Example patterns (non-explicit examples for demonstration)
            // In production, this would contain actual inappropriate terms
            "דוגמא1".to_string(),
            "דוגמא2".to_string(),
            "דוגמא3".to_string(),
        ]
    }

    /// Load blacklist from file
    pub fn load_blacklist_from_file(path: &str) -> Result<Vec<String>, std::io::Error> {
        use std::fs::File;
        use std::io::{BufRead, BufReader};

        let file = File::open(path)?;
        let reader = BufReader::new(file);

        let mut words = Vec::new();
        for line in reader.lines() {
            let line = line?;
            let trimmed = line.trim();
            if !trimmed.is_empty() && !trimmed.starts_with('#') {
                words.push(trimmed.to_string());
            }
        }

        Ok(words)
    }

    /// Filter plain text
    pub fn filter_text(&self, text: &str) -> FilterResult {
        let score = self.matcher.calculate_content_score(text);

        if score >= self.threshold {
            let matches = self.matcher.find_matches(text);
            let match_words: Vec<String> = matches.iter().map(|m| m.word.clone()).collect();

            FilterResult::Inappropriate {
                score,
                matches: match_words,
            }
        } else {
            FilterResult::Clean
        }
    }

    /// Filter HTML content
    pub fn filter_html(&self, html: &str) -> FilterResult {
        let text = extract_text_from_html(html);
        self.filter_text(&text)
    }

    /// Check if content is appropriate
    pub fn is_appropriate(&self, text: &str) -> bool {
        matches!(self.filter_text(text), FilterResult::Clean)
    }

    /// Check if HTML is appropriate
    pub fn is_html_appropriate(&self, html: &str) -> bool {
        matches!(self.filter_html(html), FilterResult::Clean)
    }

    /// Get detailed statistics
    pub fn get_statistics(&self, text: &str) -> ContentStatistics {
        let words = self.matcher.tokenize_hebrew(text);
        let matches = self.matcher.find_matches(text);
        let score = self.matcher.calculate_content_score(text);
        let stats = self.matcher.get_match_statistics(text);

        ContentStatistics {
            total_words: words.len(),
            inappropriate_words: matches.len(),
            score,
            word_frequency: stats,
        }
    }

    /// Set custom threshold
    pub fn set_threshold(&mut self, threshold: u32) {
        self.threshold = threshold;
    }
}

#[derive(Debug)]
pub struct ContentStatistics {
    pub total_words: usize,
    pub inappropriate_words: usize,
    pub score: u32,
    pub word_frequency: HashMap<String, usize>,
}

impl Default for ContentFilter {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_filtering() {
        let filter = ContentFilter::with_custom_words(vec!["בדיקה".to_string()], 10);

        let clean_text = "זהו טקסט נקי לגמרי";
        assert!(filter.is_appropriate(clean_text));

        let inappropriate_text = "בדיקה בדיקה בדיקה בדיקה בדיקה";
        assert!(!filter.is_appropriate(inappropriate_text));
    }

    #[test]
    fn test_html_filtering() {
        let filter = ContentFilter::with_custom_words(vec!["רע".to_string()], 20);

        let clean_html = r#"<html><body><p>תוכן נקי ומתאים</p></body></html>"#;
        assert!(filter.is_html_appropriate(clean_html));

        let bad_html = r#"<html><body><p>רע רע רע רע רע רע רע רע</p></body></html>"#;
        assert!(!filter.is_html_appropriate(bad_html));
    }

    #[test]
    fn test_threshold() {
        let mut filter = ContentFilter::with_custom_words(vec!["מילה".to_string()], 50);

        let text = "מילה אחת מילה שתיים מילה שלוש טוב טוב טוב טוב טוב";
        assert!(filter.is_appropriate(text)); // Below 50% threshold

        filter.set_threshold(10);
        assert!(!filter.is_appropriate(text)); // Above 10% threshold
    }

    #[test]
    fn test_statistics() {
        let filter = ContentFilter::with_custom_words(vec!["בדיקה".to_string()], 10);

        let text = "בדיקה ראשונה בדיקה שנייה טקסט נקי";
        let stats = filter.get_statistics(text);

        assert_eq!(stats.total_words, 5);
        assert_eq!(stats.inappropriate_words, 2);
        assert_eq!(*stats.word_frequency.get("בדיקה").unwrap(), 2);
    }

    #[test]
    fn test_morphology_in_filter() {
        let filter = ContentFilter::with_custom_words(vec!["ספר".to_string()], 10);

        // Should catch different inflections
        assert!(!filter.is_appropriate("ספר ספרים הספר בספר"));
        assert!(filter.is_appropriate("טקסט נקי לחלוטין"));
    }
}
