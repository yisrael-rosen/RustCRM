package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"time"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s <input_file> <search_pattern>\n", os.Args[0])
		os.Exit(1)
	}

	inputPath := os.Args[1]
	pattern := os.Args[2]

	// Start timing
	start := time.Now()

	// Open input file
	file, err := os.Open(inputPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	// Filter lines
	scanner := bufio.NewScanner(file)
	var matchCount int
	var totalLines int
	var output strings.Builder

	for scanner.Scan() {
		line := scanner.Text()
		totalLines++
		if strings.Contains(line, pattern) {
			matchCount++
			output.WriteString(line)
			output.WriteByte('\n')
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Error reading file: %v\n", err)
		os.Exit(1)
	}

	// End timing
	elapsed := time.Since(start)

	// Print results
	fmt.Println("\n=== Go Text Filter ===")
	fmt.Printf("Total lines: %d\n", totalLines)
	fmt.Printf("Matching lines: %d\n", matchCount)
	fmt.Printf("Time elapsed: %dms\n", elapsed.Milliseconds())
	fmt.Printf("Output size: %d bytes\n", output.Len())
}
