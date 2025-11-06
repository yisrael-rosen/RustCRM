package main

import (
	"bytes"
	"fmt"
	"os"
	"runtime"
	"sync"
	"time"
)

type ChunkResult struct {
	totalLines int
	matchCount int
	outputSize int
}

func processChunk(chunk []byte, pattern []byte, wg *sync.WaitGroup, results chan<- ChunkResult) {
	defer wg.Done()

	var totalLines, matchCount, outputSize int
	lines := bytes.Split(chunk, []byte{'\n'})

	for _, line := range lines {
		totalLines++
		if bytes.Contains(line, pattern) {
			matchCount++
			outputSize += len(line) + 1
		}
	}

	results <- ChunkResult{
		totalLines: totalLines,
		matchCount: matchCount,
		outputSize: outputSize,
	}
}

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s <input_file> <search_pattern>\n", os.Args[0])
		os.Exit(1)
	}

	inputPath := os.Args[1]
	pattern := []byte(os.Args[2])

	// Start timing
	start := time.Now()

	// Read entire file
	content, err := os.ReadFile(inputPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading file: %v\n", err)
		os.Exit(1)
	}

	// Get CPU count for optimal parallelism
	numWorkers := runtime.NumCPU()
	if numWorkers > 8 {
		numWorkers = 8 // Cap at 8 goroutines
	}

	// Calculate chunk size
	chunkSize := len(content) / numWorkers
	if chunkSize == 0 {
		chunkSize = len(content)
		numWorkers = 1
	}

	// Create channels and wait group
	results := make(chan ChunkResult, numWorkers)
	var wg sync.WaitGroup

	// Spawn goroutines to process chunks
	for i := 0; i < numWorkers; i++ {
		start := i * chunkSize
		end := start + chunkSize
		if i == numWorkers-1 {
			end = len(content)
		}

		chunk := content[start:end]
		wg.Add(1)
		go processChunk(chunk, pattern, &wg, results)
	}

	// Wait for all goroutines and close results channel
	go func() {
		wg.Wait()
		close(results)
	}()

	// Aggregate results
	var totalLines, matchCount, outputSize int
	for result := range results {
		totalLines += result.totalLines
		matchCount += result.matchCount
		outputSize += result.outputSize
	}

	// End timing
	elapsed := time.Since(start)

	// Print results
	fmt.Println("\n=== Go Optimized Text Filter ===")
	fmt.Printf("Total lines: %d\n", totalLines)
	fmt.Printf("Matching lines: %d\n", matchCount)
	fmt.Printf("Time elapsed: %dms\n", elapsed.Milliseconds())
	fmt.Printf("Output size: %d bytes\n", outputSize)
	fmt.Printf("Workers used: %d\n", numWorkers)
}
