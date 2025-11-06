use crate::hebrew_morphology::HebrewMorphology;
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct MatchResult {
    pub word: String,
    pub position: usize,
    pub matched_pattern: String,
}

pub struct PatternMatcher {
    morphology: HebrewMorphology,
}

impl PatternMatcher {
    pub fn new(base_words: Vec<String>) -> Self {
        Self {
            morphology: HebrewMorphology::new(base_words),
        }
    }

    /// Find all matches in text
    pub fn find_matches(&self, text: &str) -> Vec<MatchResult> {
        let mut matches = Vec::new();
        let words = self.tokenize_hebrew(text);

        for (position, word) in words.iter().enumerate() {
            if self.morphology.matches_with_morphology(word) {
                matches.push(MatchResult {
                    word: word.clone(),
                    position,
                    matched_pattern: word.clone(),
                });
            }
        }

        matches
    }

    /// Check if text contains any inappropriate content
    pub fn contains_inappropriate_content(&self, text: &str) -> bool {
        let words = self.tokenize_hebrew(text);

        for word in words {
            if self.morphology.matches_with_morphology(&word) {
                return true;
            }
        }

        false
    }

    /// Tokenize Hebrew text into words
    pub fn tokenize_hebrew(&self, text: &str) -> Vec<String> {
        // Split by whitespace and punctuation
        let mut words = Vec::new();

        let mut current_word = String::new();

        for ch in text.chars() {
            if ch.is_whitespace() || self.is_punctuation(ch) {
                if !current_word.is_empty() {
                    words.push(current_word.clone());
                    current_word.clear();
                }
            } else if self.is_hebrew_char(ch) || ch.is_ascii_alphabetic() {
                current_word.push(ch);
            }
        }

        if !current_word.is_empty() {
            words.push(current_word);
        }

        words
    }

    /// Check if character is Hebrew
    fn is_hebrew_char(&self, ch: char) -> bool {
        ('\u{0590}'..='\u{05FF}').contains(&ch) // Hebrew Unicode range
    }

    /// Check if character is punctuation
    fn is_punctuation(&self, ch: char) -> bool {
        matches!(ch, '.' | ',' | '!' | '?' | ';' | ':' | '-' | '(' | ')' | '[' | ']' | '"' | '\'' | '/' | '\\')
    }

    /// Get statistics about matches
    pub fn get_match_statistics(&self, text: &str) -> HashMap<String, usize> {
        let matches = self.find_matches(text);
        let mut stats = HashMap::new();

        for match_result in matches {
            *stats.entry(match_result.word).or_insert(0) += 1;
        }

        stats
    }

    /// Calculate content score (0-100, higher = more inappropriate)
    pub fn calculate_content_score(&self, text: &str) -> u32 {
        let words = self.tokenize_hebrew(text);
        if words.is_empty() {
            return 0;
        }

        let matches = self.find_matches(text);
        let match_count = matches.len();
        let total_words = words.len();

        // Calculate percentage of inappropriate words
        let percentage = (match_count as f64 / total_words as f64) * 100.0;

        // Cap at 100
        percentage.min(100.0) as u32
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenization() {
        let matcher = PatternMatcher::new(vec![]);
        let words = matcher.tokenize_hebrew("שלום עולם, איך הולך?");

        assert_eq!(words.len(), 4);
        assert_eq!(words[0], "שלום");
        assert_eq!(words[1], "עולם");
        assert_eq!(words[2], "איך");
        assert_eq!(words[3], "הולך");
    }

    #[test]
    fn test_pattern_matching() {
        let matcher = PatternMatcher::new(vec!["בדיקה".to_string()]);

        let text = "זוהי בדיקה של המערכת";
        assert!(matcher.contains_inappropriate_content(text));

        let text_clean = "זהו טקסט נקי לגמרי";
        assert!(!matcher.contains_inappropriate_content(text_clean));
    }

    #[test]
    fn test_morphology_matching() {
        let matcher = PatternMatcher::new(vec!["ספר".to_string()]);

        assert!(matcher.contains_inappropriate_content("קראתי ספר"));
        assert!(matcher.contains_inappropriate_content("הספר הזה"));
        assert!(matcher.contains_inappropriate_content("ספרים רבים"));
    }

    #[test]
    fn test_match_statistics() {
        let matcher = PatternMatcher::new(vec!["בדיקה".to_string()]);

        let text = "בדיקה ראשונה, בדיקה שנייה, בדיקה שלישית";
        let stats = matcher.get_match_statistics(text);

        assert_eq!(*stats.get("בדיקה").unwrap_or(&0), 3);
    }

    #[test]
    fn test_content_score() {
        let matcher = PatternMatcher::new(vec!["רע".to_string()]);

        let text_high = "רע רע רע רע רע";
        let score_high = matcher.calculate_content_score(text_high);
        assert!(score_high > 50);

        let text_low = "טוב טוב טוב טוב רע";
        let score_low = matcher.calculate_content_score(text_low);
        assert!(score_low < 50);

        let text_clean = "טקסט נקי לחלוטין";
        let score_clean = matcher.calculate_content_score(text_clean);
        assert_eq!(score_clean, 0);
    }
}
