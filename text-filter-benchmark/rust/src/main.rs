use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::time::Instant;

fn main() -> std::io::Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 3 {
        eprintln!("Usage: {} <input_file> <search_pattern>", args[0]);
        std::process::exit(1);
    }

    let input_path = &args[1];
    let pattern = &args[2];

    // Start timing
    let start = Instant::now();

    // Open input file
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);

    // Filter lines
    let mut match_count = 0;
    let mut total_lines = 0;
    let mut output = String::new();

    for line in reader.lines() {
        let line = line?;
        total_lines += 1;
        if line.contains(pattern) {
            match_count += 1;
            output.push_str(&line);
            output.push('\n');
        }
    }

    // End timing
    let elapsed = start.elapsed();

    // Print results
    println!("\n=== Rust Text Filter ===");
    println!("Total lines: {}", total_lines);
    println!("Matching lines: {}", match_count);
    println!("Time elapsed: {}ms", elapsed.as_millis());
    println!("Output size: {} bytes", output.len());

    Ok(())
}
