# frozen_string_literal: true

require "net/http"
require_relative "parser/base"
require_relative "http_stream"

module XmlNodeStream
  # The abstract parser class that wraps the actual parser implementation.
  class Parser
    SUPPORTED_PARSERS = [:nokogiri, :libxml, :rexml]

    class << self
      # Set the parser implementation. The parser argument should be one of :nokogiri, :libxml, or :rexml. If this method
      # is not called, it will default to :rexml which is the slowest choice possible. If you set the parser to one of the
      # other values, though, you'll need to make sure you have the nokogiri gem or libxml-ruby gem installed.
      #
      # @param parser [Symbol, String] the parser name (:nokogiri, :libxml, or :rexml)
      # @return [Symbol] the parser name
      # @raise [ArgumentError] if parser is not one of the supported parsers
      def parser_name=(parser)
        parser_sym = parser&.to_sym
        raise ArgumentError.new("must be one of #{SUPPORTED_PARSERS.inspect}") unless SUPPORTED_PARSERS.include?(parser_sym)

        @parser_name = parser_sym
      end

      # Get the name of the current parser.
      #
      # @return [Symbol] the current parser name
      def parser_name
        @parser_name ||= :rexml
      end

      # Parse the document specified in io. This can be either a Stream, URI, Pathname, or String. If it is a String,
      # it can either be a XML document, file system path, or URI. The parser will figure it out. If a block is given,
      # it will be yielded to with each node as it is parsed.
      #
      # @param io [IO, String, URI, Pathname] the input source to parse
      # @yield [Node] each node as it is parsed
      # @return [Node] the root node of the parsed document
      def parse(io, &block)
        close_stream = true
        io = URI.parse(io) if io.is_a?(String) && io.match?(%r{\Ahttp(s)?://})

        if io.is_a?(String) && io.match?(/<[^>]+>/m)
          io = StringIO.new(io)
        elsif io.is_a?(String)
          unless File.exist?(io)
            raise ArgumentError.new("File not found: #{io}")
          end
          io = File.open(io, "r:UTF-8")
        elsif io.is_a?(Pathname)
          unless io.exist?
            raise ArgumentError.new("File not found: #{io}")
          end
          io = io.open("r:UTF-8")
        elsif io.is_a?(URI)
          io = HttpStream.new(io)
        else
          close_stream = false
        end

        begin
          parser = parser_class(parser_name).new(&block)
          parser.parse_stream(io)
          parser.root
        ensure
          if close_stream
            begin
              io.close
            rescue
              # Ignore errors during close to ensure cleanup completes
              nil
            end
          end
        end
      end

      protected

      def parser_class(class_symbol)
        @loaded_parsers ||= {}
        klass = @loaded_parsers[class_symbol]
        unless klass
          require File.expand_path(File.join(File.dirname(__FILE__), "parser", "#{class_symbol}_parser"))
          class_name = "#{class_symbol.to_s.capitalize}Parser"
          klass = const_get(class_name)
          @loaded_parsers[class_symbol] = klass
        end
        klass
      end
    end
  end
end
