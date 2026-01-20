# Benchmarks

This directory contains benchmark tests for the XML Node Stream gem.

## Overview

The benchmarks test the performance of different XML parsers in two scenarios:

1. **Streaming parsing** - Using the XmlNodeStream gem to parse XML incrementally
2. **Direct parsing** - Loading the entire XML document into memory using the parser's native API

Each benchmark:
- Generates a large XML file (50 authors, 10 sections, 20 books per section = 200 books total)
- Parses the file and extracts all book IDs
- Measures execution time and memory usage

## Available Parsers

- **Nokogiri** - Fast, native extension-based parser (requires nokogiri gem)
- **LibXML** - Fast, native extension-based parser (requires libxml-ruby gem)
- **REXML** - Pure Ruby parser (slowest, but no dependencies)

## Running Benchmarks

### Run all benchmarks
```bash
rake benchmark
```

### Run streaming benchmarks
```bash
rake benchmark:streaming:nokogiri
rake benchmark:streaming:libxml
rake benchmark:streaming:rexml
```

### Run direct parsing benchmarks
```bash
rake benchmark:direct:nokogiri
rake benchmark:direct:libxml
rake benchmark:direct:rexml
```

## Output

Each benchmark displays:
- File size generated
- Number of book IDs extracted
- Execution time in seconds
- Memory usage in MB

## Files

- `generator.rb` - Generates test XML files with consistent, reproducible data
- `benchmark_helper.rb` - Contains benchmark runner classes and memory measurement utilities
