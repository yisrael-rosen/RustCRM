use hebrew_content_filter::{ContentFilter, FilterResult};

fn main() {
    println!("Hebrew Content Filter - Basic Usage Examples\n");

    // Example 1: Create filter with custom words
    println!("=== Example 1: Basic Text Filtering ===");
    let filter = ContentFilter::with_custom_words(
        vec!["רע".to_string(), "גרוע".to_string()],
        15, // 15% threshold
    );

    let clean_text = "שלום עולם, זהו יום נפלא";
    println!("Text: {}", clean_text);
    println!("Result: {:?}\n", filter.filter_text(clean_text));

    let inappropriate_text = "זה רע רע רע רע רע";
    println!("Text: {}", inappropriate_text);
    println!("Result: {:?}\n", filter.filter_text(inappropriate_text));

    // Example 2: Hebrew morphology demonstration
    println!("=== Example 2: Hebrew Morphology ===");
    let morph_filter = ContentFilter::with_custom_words(vec!["ספר".to_string()], 10);

    let test_words = vec![
        "ספר",      // book
        "ספרים",    // books
        "הספר",     // the book
        "בספרים",   // in books
        "ספרי",     // my book
    ];

    for word in test_words {
        let result = morph_filter.filter_text(word);
        println!("{} => {:?}", word, result);
    }

    // Example 3: HTML filtering
    println!("\n=== Example 3: HTML Content Filtering ===");
    let html = r#"
        <html>
            <head><title>דף בדיקה</title></head>
            <body>
                <h1>כותרת</h1>
                <p>תוכן טוב ונקי</p>
                <script>
                    // Scripts are filtered out
                    var bad = "רע";
                </script>
            </body>
        </html>
    "#;

    match filter.filter_html(html) {
        FilterResult::Clean => println!("HTML content is clean"),
        FilterResult::Inappropriate { score, matches } => {
            println!("HTML content flagged!");
            println!("Score: {}", score);
            println!("Matches: {:?}", matches);
        }
    }

    // Example 4: Statistics
    println!("\n=== Example 4: Detailed Statistics ===");
    let text = "טקסט טוב טוב רע גרוע רע";
    let stats = filter.get_statistics(text);

    println!("Text: {}", text);
    println!("Total words: {}", stats.total_words);
    println!("Inappropriate words: {}", stats.inappropriate_words);
    println!("Score: {}", stats.score);
    println!("Word frequencies:");
    for (word, count) in stats.word_frequency {
        println!("  {} appeared {} times", word, count);
    }

    // Example 5: Load from file
    println!("\n=== Example 5: Load Blacklist from File ===");
    match ContentFilter::load_blacklist_from_file("data/blacklist_example.txt") {
        Ok(words) => {
            println!("Loaded {} words from blacklist", words.len());
            let file_filter = ContentFilter::with_custom_words(words, 20);
            println!("Filter created successfully");

            let test = "זוהי בדיקה פשוטה";
            println!("Testing: {}", test);
            println!("Result: {:?}", file_filter.filter_text(test));
        }
        Err(e) => println!("Error loading blacklist: {}", e),
    }

    println!("\n=== All Examples Complete! ===");
}
