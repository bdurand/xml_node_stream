# frozen_string_literal: true

require "tempfile"

require_relative "../lib/xml_node_stream"
require_relative "generator"

module Benchmark
  # Helper methods for benchmarking
  class Helper
    # Measure execution time
    def self.measure
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      end_time - start_time
    end

    def self.memory
      GC.start
      memory_before = get_process_memory
      yield
      GC.start
      memory_after = get_process_memory

      memory_after - memory_before
    end

    private

    def self.get_process_memory
      # Get process memory (RSS) in MB - includes both Ruby heap and native C allocations
      if RUBY_PLATFORM =~ /darwin/
        # macOS - use ps to get RSS in KB
        `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
      elsif RUBY_PLATFORM =~ /linux/
        # Linux - read from /proc
        status_file = "/proc/#{Process.pid}/status"
        if File.exist?(status_file)
          File.read(status_file).match(/VmRSS:\s+(\d+)/)[1].to_i / 1024.0
        else
          # Fallback to ps
          `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
        end
      else
        # Fallback using Ruby's GC stats (Ruby heap only)
        stat = GC.stat
        slot_size = 40
        stat[:heap_live_slots] * slot_size / (1024.0 * 1024.0)
      end
    end
  end

  # Base benchmark runner
  class Runner
    attr_reader :file_path, :parser_name, :size_mb, :tempfile

    def initialize(parser_name, size_mb: 1)
      @parser_name = parser_name
      @tempfile = nil
      @file_path = nil
      @size_mb = size_mb
    end

    def setup
      @tempfile = Generator.new.generate(size_mb: size_mb)
      @file_path = @tempfile.path
    end

    def cleanup
      @tempfile.unlink if @tempfile
    end

    def run
      raise NotImplementedError, "Subclasses must implement run method"
    end

    def execute
      setup

      puts "\n#{self.class.name} - Parser: #{parser_name}"
      puts "=" * 60

      book_ids = nil
      memory_used = nil
      time = Helper.measure do
        book_ids, memory_used = run
      end

      expected_count = @tempfile.book_count
      raise "Expected #{expected_count} book IDs, got #{book_ids.size}" unless book_ids.size == expected_count

      puts "Extracted #{book_ids.size} book IDs"
      puts "XML file size: #{(File.size(@file_path).to_f / (1024 * 1024)).round(1)} MB"
      puts "Time: #{time.round(3)} seconds"
      puts "Memory used: #{memory_used.round(1)} MB"

      cleanup
    end
  end

  # Benchmark using the gem's streaming parser
  class StreamingBenchmark < Runner
    def run
      XmlNodeStream::Parser.parser_name = parser_name
      ids = []

      memory_used = Helper.memory do
        XmlNodeStream.parse(file_path) do |node|
          if node.name == "book"
            ids << node.attributes["id"]
            node.release!
          elsif node.name == "author" || node.name == "section"
            node.release!
          end
        end
      end

      [ids, memory_used]
    end
  end

  # Benchmark using direct parser (load entire document)
  class DirectBenchmark < Runner
    def run
      case parser_name
      when :nokogiri
        require "nokogiri"
        run_nokogiri
      when :libxml
        require "libxml"
        run_libxml
      when :rexml
        require "rexml/document"
        run_rexml
      else
        raise ArgumentError, "Unknown parser: #{parser_name}"
      end
    end

    private

    def run_nokogiri
      ids = nil
      memory_used = Helper.memory do
        doc = Nokogiri::XML(File.read(file_path))
        ids = doc.xpath("//book/@id").map(&:value)
      end
      [ids, memory_used]
    end

    def run_libxml
      ids = nil
      memory_used = Helper.memory do
        doc = LibXML::XML::Document.file(file_path)
        ids = doc.find("//book/@id").map(&:value)
      end
      [ids, memory_used]
    end

    def run_rexml
      ids = []
      memory_used = Helper.memory do
        doc = REXML::Document.new(File.read(file_path))
        ids = []
        doc.elements.each("//book") do |book|
          ids << book.attributes["id"]
        end
      end
      [ids, memory_used]
    end
  end
end
