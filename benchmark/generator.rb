# frozen_string_literal: true

require "fileutils"
require "tempfile"

module Benchmark
  # Generate a large XML file for benchmarking
  class Generator
    SECTIONS = ["History", "Fiction", "Science", "Biography", "Mystery", "Romance", "Fantasy", "Horror", "Thriller", "Adventure"].freeze
    AUTHORS_FIRST_NAMES = ["John", "Jane", "Robert", "Mary", "Michael", "Sarah", "William", "Elizabeth", "James", "Linda"].freeze
    AUTHORS_LAST_NAMES = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"].freeze
    ADJECTIVES = ["Great", "Lost", "Hidden", "Ancient", "Modern", "Dark", "Bright", "Silent", "Loud", "Mystery"].freeze
    NOUNS = ["Journey", "Story", "Tale", "Chronicle", "Legend", "History", "Adventure", "Quest", "Secret", "Discovery"].freeze
    ABSTRACT_WORDS = ["adventure", "story", "tale", "journey", "quest", "exploration", "discovery", "mystery", "thriller", "drama"].freeze

    BOOKS_PER_SECTION = 100
    AUTHORS_PER_MB = 100

    def initialize(seed = 12345)
      @seed = seed
    end

    def generate(size_mb: 1)
      tempfile = Tempfile.new(["xml_node_stream_benchmark", ".xml"])
      tempfile.binmode

      target_size_bytes = size_mb * 1024 * 1024
      authors = (size_mb * AUTHORS_PER_MB).to_i
      books_per_section = BOOKS_PER_SECTION

      tempfile.puts '<?xml version="1.0"?>'
      tempfile.puts "<library>"
      tempfile.puts "  <?library-info version=\"2.0\" ignore=\"yes\" ?>"
      tempfile.puts "  <!-- Authors -->"
      tempfile.puts "  <authors>"

      # Generate authors
      authors.times do |i|
        author_id = i + 1
        tempfile.puts "    <author id=\"#{author_id}\">"
        tempfile.puts "      <name>#{generate_author_name(author_id)}</name>"
        tempfile.puts "    </author>"
      end

      tempfile.puts "  </authors>"
      tempfile.puts "  <!-- Books -->"
      tempfile.puts "  <collection>"

      # Generate sections with books until we exceed target size
      book_id = 1
      section_num = 0
      loop do
        section_num += 1
        section_id = section_num * 100
        section_name = generate_section_name(section_num - 1)
        tempfile.puts "    <section id=\"#{section_id}\" name=\"#{section_name}\">"

        books_per_section.times do |j|
          author_id = (book_id % authors) + 1
          tempfile.puts "      <book id=\"#{book_id}\">"
          tempfile.puts "        <title>"
          tempfile.puts "          #{generate_title(book_id)}"
          tempfile.puts "        </title>"
          tempfile.puts "        <author id=\"#{author_id}\"/>"
          tempfile.puts "        <abstract><![CDATA[#{generate_abstract(book_id)}]]></abstract>"
          tempfile.puts "        <volumes>#{(book_id % 10) + 1}</volumes>" if book_id % 3 == 0
          tempfile.puts "      </book>"
          book_id += 1
        end

        tempfile.puts "    </section>"

        # Check if we've exceeded the target size
        tempfile.flush
        break if tempfile.size >= target_size_bytes
      end

      tempfile.puts "  </collection>"
      tempfile.puts "</library>"
      tempfile.close

      # Store metadata for verification
      tempfile.instance_variable_set(:@book_count, book_id - 1)
      tempfile.define_singleton_method(:book_count) { @book_count }

      tempfile
    end

    private

    def generate_author_name(id)
      # Use seeded random to generate consistent names
      random = Random.new(id * @seed)
      "#{AUTHORS_FIRST_NAMES[random.rand(AUTHORS_FIRST_NAMES.size)]} #{AUTHORS_LAST_NAMES[random.rand(AUTHORS_LAST_NAMES.size)]}"
    end

    def generate_section_name(index)
      "#{SECTIONS[index % SECTIONS.size]} (#{index + 1})"
    end

    def generate_title(id)
      # Generate consistent titles based on id
      random = Random.new(id * @seed)
      "The #{ADJECTIVES[random.rand(ADJECTIVES.size)]} #{NOUNS[random.rand(NOUNS.size)]} (Vol. #{id})"
    end

    def generate_abstract(id)
      # Generate consistent abstracts of approximately the same length
      random = Random.new(id * @seed)
      abstract = []
      20.times do
        abstract << ABSTRACT_WORDS[random.rand(ABSTRACT_WORDS.size)]
      end
      "This is an exciting #{abstract.join(' ')} that captivates readers."
    end
  end
end
