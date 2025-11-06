use std::env;
use std::fs::File;
use std::time::Instant;
use memmap2::Mmap;
use rayon::prelude::*;

fn main() -> std::io::Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 3 {
        eprintln!("Usage: {} <input_file> <search_pattern>", args[0]);
        std::process::exit(1);
    }

    let input_path = &args[1];
    let pattern = args[2].as_bytes();

    // Start timing
    let start = Instant::now();

    // Memory-map the file for zero-copy access
    let file = File::open(input_path)?;
    let mmap = unsafe { Mmap::map(&file)? };
    let content = &mmap[..];

    // Split into lines and process in parallel
    let results: Vec<(usize, usize)> = content
        .par_split(|&b| b == b'\n')
        .map(|line| {
            let matches = if memchr::memmem::find(line, pattern).is_some() {
                1
            } else {
                0
            };
            (1, matches) // (total_lines, match_count)
        })
        .collect();

    // Aggregate results
    let (total_lines, match_count) = results.iter()
        .fold((0, 0), |(lines, matches), (l, m)| (lines + l, matches + m));

    // Calculate output size (if we were to output)
    let output_size: usize = content
        .split(|&b| b == b'\n')
        .filter(|line| memchr::memmem::find(line, pattern).is_some())
        .map(|line| line.len() + 1)
        .sum();

    // End timing
    let elapsed = start.elapsed();

    // Print results
    println!("\n=== Rust Optimized Text Filter ===");
    println!("Total lines: {}", total_lines);
    println!("Matching lines: {}", match_count);
    println!("Time elapsed: {}ms", elapsed.as_millis());
    println!("Output size: {} bytes", output_size);

    Ok(())
}
