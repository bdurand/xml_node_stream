# Quick Start - Benchmarks

## Run All Benchmarks
```bash
bundle exec rake benchmark:all
```

## Run Individual Benchmarks

### Streaming (using XmlNodeStream gem)
```bash
bundle exec rake benchmark:streaming:nokogiri
bundle exec rake benchmark:streaming:libxml
bundle exec rake benchmark:streaming:rexml
```

### Direct (native parser API)
```bash
bundle exec rake benchmark:direct:nokogiri
bundle exec rake benchmark:direct:libxml
bundle exec rake benchmark:direct:rexml
```

## What Gets Tested

Each benchmark:
1. Generates a 0.08 MB XML file with 50 authors, 10 sections, 20 books/section (200 books total)
2. Parses the file and extracts all 200 book IDs
3. Reports execution time (seconds) and memory usage (MB)

## Key Differences

**Streaming**: Uses `XmlNodeStream.parse` to process XML incrementally
- Lower memory for large files
- Processes nodes as they are encountered

**Direct**: Uses native parser API to load entire document
- Faster for small files
- Loads full XML tree into memory

## See Also

- [README.md](README.md) - Detailed documentation
- [SUMMARY.md](SUMMARY.md) - Implementation overview
