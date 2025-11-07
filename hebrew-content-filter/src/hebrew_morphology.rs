use std::collections::HashSet;

/// Hebrew morphology handler for word roots and inflections
pub struct HebrewMorphology {
    /// Base roots/words to check
    base_words: HashSet<String>,
}

impl HebrewMorphology {
    pub fn new(base_words: Vec<String>) -> Self {
        Self {
            base_words: base_words.into_iter().collect(),
        }
    }

    /// Generate all possible inflections for a Hebrew word
    pub fn generate_inflections(&self, root: &str) -> HashSet<String> {
        let mut inflections = HashSet::new();

        // Add the base word
        inflections.insert(root.to_string());

        // Hebrew prefixes (ה, ו, ב, כ, ל, מ, ש)
        let prefixes = vec!["ה", "ו", "ב", "כ", "ל", "מ", "ש", "וה", "וב", "וכ", "ול", "ומ", "וש"];

        // Hebrew suffixes for plural, possessive, etc.
        let suffixes = vec![
            "ים", "ות", "י", "ך", "כם", "כן", "ה", "ו", "ן", "נו", "כם", "הם", "הן",
            "יה", "יו", "ינו", "יכם", "יכן", "יהם", "יהן", "ת", "תי", "ת", "תם", "תן"
        ];

        // Add variations with prefixes
        for prefix in &prefixes {
            inflections.insert(format!("{}{}", prefix, root));

            // Combine with suffixes
            for suffix in &suffixes {
                inflections.insert(format!("{}{}{}", prefix, root, suffix));
            }
        }

        // Add variations with suffixes only
        for suffix in &suffixes {
            inflections.insert(format!("{}{}", root, suffix));
        }

        // Handle double prefixes (common in Hebrew)
        inflections.insert(format!("וב{}", root));
        inflections.insert(format!("וכ{}", root));
        inflections.insert(format!("ול{}", root));
        inflections.insert(format!("ומ{}", root));

        inflections
    }

    /// Check if a word matches any base word or its inflections
    pub fn matches_pattern(&self, word: &str) -> bool {
        // Direct match
        if self.base_words.contains(word) {
            return true;
        }

        // Check against all base words and their inflections
        for base_word in &self.base_words {
            let inflections = self.generate_inflections(base_word);
            if inflections.contains(word) {
                return true;
            }
        }

        false
    }

    /// Remove common Hebrew prefixes to find root
    pub fn strip_prefixes(&self, word: &str) -> Vec<String> {
        let mut candidates = vec![word.to_string()];

        let prefixes = vec!["ה", "ו", "ב", "כ", "ל", "מ", "ש", "וה", "וב", "וכ", "ול", "ומ"];

        for prefix in prefixes {
            if word.starts_with(prefix) {
                let stripped = &word[prefix.len()..];
                if !stripped.is_empty() {
                    candidates.push(stripped.to_string());
                }
            }
        }

        candidates
    }

    /// Remove common Hebrew suffixes
    pub fn strip_suffixes(&self, word: &str) -> Vec<String> {
        let mut candidates = vec![word.to_string()];

        let suffixes = vec!["ים", "ות", "י", "ך", "כם", "כן", "ה", "ו", "ן", "נו", "יה", "יו"];

        for suffix in suffixes {
            if word.ends_with(suffix) && word.len() > suffix.len() {
                let stripped = &word[..word.len() - suffix.len()];
                if !stripped.is_empty() {
                    candidates.push(stripped.to_string());
                }
            }
        }

        candidates
    }

    /// Advanced matching: strip prefixes and suffixes to find root
    pub fn matches_with_morphology(&self, word: &str) -> bool {
        // Try direct match first
        if self.base_words.contains(word) {
            return true;
        }

        // Try stripping prefixes
        for prefix_stripped in self.strip_prefixes(word) {
            if self.base_words.contains(&prefix_stripped) {
                return true;
            }

            // Try stripping suffixes from prefix-stripped word
            for suffix_stripped in self.strip_suffixes(&prefix_stripped) {
                if self.base_words.contains(&suffix_stripped) {
                    return true;
                }
            }
        }

        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_inflections() {
        let morph = HebrewMorphology::new(vec!["בית".to_string()]);
        let inflections = morph.generate_inflections("בית");

        // Should contain various forms
        assert!(inflections.contains("בית"));
        assert!(inflections.contains("הבית"));
        assert!(inflections.contains("בבית"));
        assert!(inflections.contains("בתים"));
    }

    #[test]
    fn test_prefix_stripping() {
        let morph = HebrewMorphology::new(vec![]);
        let stripped = morph.strip_prefixes("והבית");

        assert!(stripped.contains(&"בית".to_string()));
        assert!(stripped.contains(&"הבית".to_string()));
    }

    #[test]
    fn test_matching() {
        let morph = HebrewMorphology::new(vec!["ספר".to_string()]);

        assert!(morph.matches_with_morphology("ספר"));
        assert!(morph.matches_with_morphology("הספר"));
        assert!(morph.matches_with_morphology("ספרים"));
        assert!(morph.matches_with_morphology("בספר"));
    }
}
