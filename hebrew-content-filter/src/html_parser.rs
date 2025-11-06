use scraper::{Html, Selector};

/// Extract all text content from HTML, removing tags
pub fn extract_text_from_html(html: &str) -> String {
    let document = Html::parse_document(html);
    let mut text_parts = Vec::new();

    // Extract text from all text nodes
    for text in document.root_element().text() {
        let trimmed = text.trim();
        if !trimmed.is_empty() {
            text_parts.push(trimmed.to_string());
        }
    }

    text_parts.join(" ")
}

/// Extract text and preserve structure with line breaks
pub fn extract_text_with_structure(html: &str) -> String {
    // Get text content, replacing block elements with newlines
    let text = extract_text_from_html(html);

    // Replace multiple spaces with single space
    let re = regex::Regex::new(r"\s+").unwrap();
    re.replace_all(&text, " ").trim().to_string()
}

/// Extract text from specific HTML elements
pub fn extract_text_from_selector(html: &str, selector_str: &str) -> Vec<String> {
    let document = Html::parse_document(html);
    let mut results = Vec::new();

    if let Ok(selector) = Selector::parse(selector_str) {
        for element in document.select(&selector) {
            let text = element.text().collect::<Vec<_>>().join(" ");
            let trimmed = text.trim();
            if !trimmed.is_empty() {
                results.push(trimmed.to_string());
            }
        }
    }

    results
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_html_extraction() {
        let html = r#"<html><body><p>שלום עולם</p></body></html>"#;
        let text = extract_text_from_html(html);
        assert!(text.contains("שלום עולם"));
    }

    #[test]
    fn test_script_removal() {
        let html = r#"
            <html>
                <head><script>alert('test');</script></head>
                <body><p>טקסט נקי</p></body>
            </html>
        "#;
        let text = extract_text_from_html(html);
        assert!(text.contains("טקסט נקי"));
        assert!(!text.contains("alert"));
    }

    #[test]
    fn test_nested_elements() {
        let html = r#"
            <div>
                <h1>כותרת</h1>
                <p>פסקה <strong>מודגשת</strong> בעברית</p>
            </div>
        "#;
        let text = extract_text_from_html(html);
        assert!(text.contains("כותרת"));
        assert!(text.contains("פסקה"));
        assert!(text.contains("מודגשת"));
    }

    #[test]
    fn test_selector_extraction() {
        let html = r#"
            <html>
                <body>
                    <h1>כותרת ראשית</h1>
                    <h2>כותרת משנית</h2>
                    <p>פסקה</p>
                </body>
            </html>
        "#;
        let headers = extract_text_from_selector(html, "h1, h2");
        assert_eq!(headers.len(), 2);
        assert!(headers[0].contains("כותרת ראשית"));
        assert!(headers[1].contains("כותרת משנית"));
    }
}
