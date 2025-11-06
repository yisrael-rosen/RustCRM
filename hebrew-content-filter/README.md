# Hebrew Content Filter

A high-performance content filtering system for Hebrew text and HTML, with full support for Hebrew morphology (inflections, conjugations, and word roots).

## Features

### 🔍 Core Capabilities
- **HTML Parsing**: Extract text from HTML, removing scripts and styles
- **Hebrew Morphology**: Handle Hebrew word roots, prefixes, suffixes, and inflections
- **Pattern Matching**: Detect inappropriate content with morphological awareness
- **Scoring System**: Calculate content appropriateness scores (0-100)
- **Statistics**: Detailed word frequency and match analysis

### 🇮🇱 Hebrew Language Support
- **Automatic Inflection Detection**: Recognizes all forms of Hebrew words
  - Singular/Plural (יחיד/רבים)
  - Masculine/Feminine (זכר/נקבה)
  - With prefixes: ה, ו, ב, כ, ל, מ, ש
  - With suffixes: ים, ות, י, ך, כם, etc.
- **Morphological Analysis**: Strips prefixes/suffixes to find word roots
- **Unicode Support**: Full Hebrew character range support

## Architecture

```
hebrew-content-filter/
├── src/
│   ├── lib.rs                    # Public API
│   ├── main.rs                   # CLI application
│   ├── hebrew_morphology.rs      # Hebrew word morphology handler
│   ├── html_parser.rs            # HTML text extraction
│   ├── pattern_matcher.rs        # Pattern matching engine
│   └── content_filter.rs         # Main filter logic
├── data/
│   └── blacklist_example.txt     # Example word list
├── tests/
│   ├── test_clean.html           # Clean content test
│   └── test_patterns.html        # Pattern matching test
└── Cargo.toml

```

## How It Works

### 1. Hebrew Morphology Engine

The system understands Hebrew word structure:

```rust
// Example: "ספר" (book) root generates:
ספר      // book (singular)
ספרים    // books (plural)
הספר     // the book
בספר     // in the book
ספרי     // my book
הספרים   // the books
בספרים   // in the books
// ... and many more variations
```

### 2. Pattern Matching Flow

```
Input Text
    ↓
Tokenization (split into words)
    ↓
For each word:
  1. Check direct match
  2. Strip prefixes (ה, ו, ב, כ, ל, etc.)
  3. Strip suffixes (ים, ות, י, ך, etc.)
  4. Check against root words
    ↓
Return matches + statistics
```

### 3. Scoring Algorithm

```
Score = (Inappropriate Words / Total Words) × 100

Example:
  "שלום עולם בדיקה בדיקה טקסט"
  → 2 inappropriate words out of 5 total
  → Score: 40%
```

## Installation

### Prerequisites
- Rust 1.70 or higher
- Cargo

### Build

```bash
# Clone the repository
cd hebrew-content-filter

# Build in release mode
cargo build --release

# Run tests
cargo test

# Run with examples
cargo run -- demo
```

## Usage

### Command Line

```bash
# Filter plain text
cargo run -- filter-text "טקסט לבדיקה"

# Filter text file
cargo run -- filter-file input.txt

# Filter HTML file
cargo run -- filter-html page.html

# Run demonstration
cargo run -- demo

# Run performance benchmark
cargo run -- benchmark
```

### As a Library

```rust
use hebrew_content_filter::{ContentFilter, FilterResult};

// Create filter with default settings
let filter = ContentFilter::new();

// Filter plain text
let text = "שלום עולם, זהו טקסט לבדיקה";
match filter.filter_text(text) {
    FilterResult::Clean => println!("Content is appropriate"),
    FilterResult::Inappropriate { score, matches } => {
        println!("Inappropriate content detected!");
        println!("Score: {}", score);
        println!("Matches: {:?}", matches);
    }
}

// Filter HTML
let html = r#"<html><body><p>תוכן HTML</p></body></html>"#;
let is_appropriate = filter.is_html_appropriate(html);

// Get detailed statistics
let stats = filter.get_statistics(text);
println!("Total words: {}", stats.total_words);
println!("Inappropriate words: {}", stats.inappropriate_words);
println!("Score: {}", stats.score);
```

### Custom Word List

```rust
// Load from file
let words = ContentFilter::load_blacklist_from_file("blacklist.txt")?;
let filter = ContentFilter::with_custom_words(words, 15);

// Or create programmatically
let custom_words = vec![
    "מילה1".to_string(),
    "מילה2".to_string(),
];
let filter = ContentFilter::with_custom_words(custom_words, 20);
```

### Adjust Threshold

```rust
let mut filter = ContentFilter::new();

// Set threshold to 25% (more lenient)
filter.set_threshold(25);

// Set threshold to 5% (more strict)
filter.set_threshold(5);
```

## Configuration

### Blacklist File Format

```
# Comments start with #
# One word per line (base form/root)
# System automatically generates inflections

מילה1
מילה2
מילה3

# Organize by category
# Category: Example
דוגמא
בדיקה
```

## Performance

Based on benchmarks:

| Text Size | Processing Time |
|-----------|-----------------|
| Short (100 words) | ~50 µs |
| Medium (1000 words) | ~500 µs |
| Long (10000 words) | ~5 ms |

**Features:**
- Compiled with LTO and opt-level 3
- Efficient Hebrew character handling
- Minimal allocations in hot paths
- Fast Unicode string operations

## Examples

### Example 1: Basic Text Filtering

```rust
let filter = ContentFilter::new();
let clean_text = "שלום עולם, מה שלומך?";
assert!(filter.is_appropriate(clean_text));
```

### Example 2: HTML Content

```rust
let html = r#"
    <html>
        <body>
            <h1>כותרת</h1>
            <p>תוכן המאמר כאן</p>
        </body>
    </html>
"#;

let filter = ContentFilter::new();
match filter.filter_html(html) {
    FilterResult::Clean => println!("HTML is clean"),
    FilterResult::Inappropriate { .. } => println!("Issues found"),
}
```

### Example 3: Word Statistics

```rust
let filter = ContentFilter::with_custom_words(
    vec!["בדיקה".to_string()],
    10
);

let text = "בדיקה ראשונה בדיקה שנייה";
let stats = filter.get_statistics(text);

println!("Found {} inappropriate words", stats.inappropriate_words);
for (word, count) in stats.word_frequency {
    println!("{}: {} occurrences", word, count);
}
```

## Testing

```bash
# Run all tests
cargo test

# Run with output
cargo test -- --nocapture

# Run specific test
cargo test test_morphology

# Run benchmark
cargo run -- benchmark
```

## API Documentation

Generate and view documentation:

```bash
cargo doc --open
```

## Use Cases

1. **Parental Controls**: Filter inappropriate content for children
2. **Corporate Filtering**: Block inappropriate content in workplace
3. **Content Moderation**: Automatic moderation for user-generated content
4. **Educational Platforms**: Ensure age-appropriate content
5. **Community Guidelines**: Enforce community standards

## Limitations

- **Context-Free**: Doesn't understand context or sarcasm
- **Blacklist-Based**: Requires maintained word list
- **False Positives**: May flag legitimate content
- **No Semantic Analysis**: Pure pattern matching

## Future Enhancements

- [ ] Machine learning-based classification
- [ ] Context-aware filtering
- [ ] Multi-language support
- [ ] Real-time streaming support
- [ ] REST API server
- [ ] Browser extension
- [ ] Semantic similarity matching

## License

This is a demonstration project for educational purposes.

## Contributing

This is a proof-of-concept implementation. In production:
1. Use comprehensive, maintained blacklists
2. Add machine learning classification
3. Implement appeal/review system
4. Add logging and monitoring
5. Include false positive handling

## Disclaimer

This tool is for **content filtering and safety purposes only**. It should be used responsibly as part of a broader content moderation strategy that includes human review and context-aware decision making.

## Support

For issues and questions, please open an issue in the repository.
