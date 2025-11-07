use hebrew_content_filter::{ContentFilter, extract_text_from_html};
use std::env;
use std::fs;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        print_usage(&args[0]);
        return;
    }

    let command = &args[1];

    match command.as_str() {
        "filter-text" => {
            if args.len() < 3 {
                eprintln!("Error: Missing text argument");
                eprintln!("Usage: {} filter-text <text>", args[0]);
                return;
            }
            let text = &args[2];
            filter_text_command(text);
        }
        "filter-file" => {
            if args.len() < 3 {
                eprintln!("Error: Missing file path");
                eprintln!("Usage: {} filter-file <path>", args[0]);
                return;
            }
            let path = &args[2];
            filter_file_command(path);
        }
        "filter-html" => {
            if args.len() < 3 {
                eprintln!("Error: Missing HTML file path");
                eprintln!("Usage: {} filter-html <path>", args[0]);
                return;
            }
            let path = &args[2];
            filter_html_command(path);
        }
        "demo" => {
            run_demo();
        }
        "benchmark" => {
            run_benchmark();
        }
        _ => {
            eprintln!("Unknown command: {}", command);
            print_usage(&args[0]);
        }
    }
}

fn print_usage(program: &str) {
    println!("Hebrew Content Filter - Usage:");
    println!();
    println!("  {} filter-text <text>    - Filter plain text", program);
    println!("  {} filter-file <path>    - Filter text file", program);
    println!("  {} filter-html <path>    - Filter HTML file", program);
    println!("  {} demo                  - Run demonstration", program);
    println!("  {} benchmark             - Run performance benchmark", program);
    println!();
    println!("Examples:");
    println!("  {} filter-text \"טקסט לבדיקה\"", program);
    println!("  {} filter-file input.txt", program);
    println!("  {} filter-html page.html", program);
}

fn filter_text_command(text: &str) {
    let filter = ContentFilter::new();

    println!("=== Hebrew Content Filter ===");
    println!("Text: {}", text);
    println!();

    let result = filter.filter_text(text);
    let stats = filter.get_statistics(text);

    println!("Result: {:?}", result);
    println!();
    println!("Statistics:");
    println!("  Total words: {}", stats.total_words);
    println!("  Inappropriate words: {}", stats.inappropriate_words);
    println!("  Score: {}", stats.score);

    if stats.inappropriate_words > 0 {
        println!();
        println!("  Word frequencies:");
        for (word, count) in stats.word_frequency {
            println!("    {} : {} times", word, count);
        }
    }
}

fn filter_file_command(path: &str) {
    match fs::read_to_string(path) {
        Ok(content) => filter_text_command(&content),
        Err(e) => eprintln!("Error reading file: {}", e),
    }
}

fn filter_html_command(path: &str) {
    match fs::read_to_string(path) {
        Ok(html) => {
            let filter = ContentFilter::new();

            println!("=== Hebrew HTML Content Filter ===");
            println!("File: {}", path);
            println!();

            let text = extract_text_from_html(&html);
            println!("Extracted text:");
            println!("{}", text);
            println!();

            let result = filter.filter_html(&html);
            let stats = filter.get_statistics(&text);

            println!("Result: {:?}", result);
            println!();
            println!("Statistics:");
            println!("  Total words: {}", stats.total_words);
            println!("  Inappropriate words: {}", stats.inappropriate_words);
            println!("  Score: {}", stats.score);
        }
        Err(e) => eprintln!("Error reading file: {}", e),
    }
}

fn run_demo() {
    println!("╔════════════════════════════════════════════╗");
    println!("║   Hebrew Content Filter - Demonstration    ║");
    println!("╚════════════════════════════════════════════╝");
    println!();

    // Create filter with example words
    let filter = ContentFilter::with_custom_words(
        vec!["בדיקה".to_string(), "דוגמא".to_string()],
        15,
    );

    // Test 1: Clean text
    println!("Test 1: Clean Hebrew text");
    let clean_text = "שלום עולם, זהו טקסט נקי ומתאים לכולם";
    println!("Input: {}", clean_text);
    println!("Result: {:?}", filter.filter_text(clean_text));
    println!();

    // Test 2: Inappropriate text
    println!("Test 2: Text with test pattern");
    let bad_text = "בדיקה ראשונה דוגמא שנייה בדיקה שלישית";
    println!("Input: {}", bad_text);
    println!("Result: {:?}", filter.filter_text(bad_text));
    println!();

    // Test 3: HTML filtering
    println!("Test 3: HTML content");
    let html = r#"
        <html>
            <head><title>דף בדיקה</title></head>
            <body>
                <h1>כותרת ראשית</h1>
                <p>זהו טקסט נקי</p>
                <p>בדיקה של המערכת</p>
            </body>
        </html>
    "#;
    println!("HTML with test patterns");
    println!("Result: {:?}", filter.filter_html(html));
    println!();

    // Test 4: Statistics
    println!("Test 4: Detailed statistics");
    let stats_text = "בדיקה בדיקה דוגמא טקסט נקי בדיקה";
    let stats = filter.get_statistics(stats_text);
    println!("Input: {}", stats_text);
    println!("Total words: {}", stats.total_words);
    println!("Inappropriate words: {}", stats.inappropriate_words);
    println!("Score: {}", stats.score);
    println!("Word frequency:");
    for (word, count) in stats.word_frequency {
        println!("  {} : {} times", word, count);
    }
    println!();

    // Test 5: Morphology
    println!("Test 5: Hebrew morphology (inflections)");
    let morph_filter = ContentFilter::with_custom_words(vec!["ספר".to_string()], 10);
    let morphology_examples = vec![
        "ספר",      // book (singular)
        "ספרים",    // books (plural)
        "הספר",     // the book
        "בספר",     // in the book
        "ספרי",     // my book
    ];

    for example in morphology_examples {
        let contains = !morph_filter.is_appropriate(example);
        println!("  {} : {}", example, if contains { "✓ Matched" } else { "✗ Not matched" });
    }

    println!();
    println!("╔════════════════════════════════════════════╗");
    println!("║         Demonstration Complete!            ║");
    println!("╚════════════════════════════════════════════╝");
}

fn run_benchmark() {
    use std::time::Instant;

    println!("╔════════════════════════════════════════════╗");
    println!("║    Hebrew Content Filter - Benchmark      ║");
    println!("╚════════════════════════════════════════════╝");
    println!();

    let filter = ContentFilter::with_custom_words(
        vec!["בדיקה".to_string(), "דוגמא".to_string()],
        15,
    );

    // Generate test data
    let short_text = "שלום עולם בדיקה של המערכת".repeat(10);
    let medium_text = "שלום עולם בדיקה של המערכת טקסט נקי דוגמא ".repeat(100);
    let long_text = "שלום עולם בדיקה של המערכת טקסט נקי דוגמא נוסף עוד טקסט ".repeat(1000);

    // Benchmark short text
    println!("Benchmark 1: Short text ({} chars)", short_text.len());
    let start = Instant::now();
    for _ in 0..1000 {
        let _ = filter.filter_text(&short_text);
    }
    let duration = start.elapsed();
    println!("  1000 iterations: {:?}", duration);
    println!("  Avg per iteration: {:?}", duration / 1000);
    println!();

    // Benchmark medium text
    println!("Benchmark 2: Medium text ({} chars)", medium_text.len());
    let start = Instant::now();
    for _ in 0..100 {
        let _ = filter.filter_text(&medium_text);
    }
    let duration = start.elapsed();
    println!("  100 iterations: {:?}", duration);
    println!("  Avg per iteration: {:?}", duration / 100);
    println!();

    // Benchmark long text
    println!("Benchmark 3: Long text ({} chars)", long_text.len());
    let start = Instant::now();
    for _ in 0..10 {
        let _ = filter.filter_text(&long_text);
    }
    let duration = start.elapsed();
    println!("  10 iterations: {:?}", duration);
    println!("  Avg per iteration: {:?}", duration / 10);
    println!();

    // Benchmark HTML filtering
    let html = format!(
        r#"<html><body><p>{}</p></body></html>"#,
        medium_text
    );
    println!("Benchmark 4: HTML filtering ({} chars)", html.len());
    let start = Instant::now();
    for _ in 0..100 {
        let _ = filter.filter_html(&html);
    }
    let duration = start.elapsed();
    println!("  100 iterations: {:?}", duration);
    println!("  Avg per iteration: {:?}", duration / 100);
    println!();

    println!("╔════════════════════════════════════════════╗");
    println!("║          Benchmark Complete!               ║");
    println!("╚════════════════════════════════════════════╝");
}
