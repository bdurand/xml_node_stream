require 'open-uri'
require 'rubygems'
require 'pathname'
require File.expand_path(File.join(File.dirname(__FILE__), 'parser', 'base'))

module XmlNodeStream
  # The abstract parser class that wraps the actual parser implementation.
  class Parser

    SUPPORTED_PARSERS = [:nokogiri, :libxml, :rexml]
    
    class << self
      # Set the parser implementation. The parser argument should be one of :nokogiri, :libxml, or :rexml. If this method
      # is not called, it will default to :rexml which is the slowest choice possible. If you set the parser to one of the
      # other values, though, you'll need to make sure you have the nokogiri gem or libxml-ruby gem installed.
      def parser_name= (parser)
        parser_sym = parser.to_sym
        raise ArgumentError.new("must be one of #{SUPPORTED_PARSERS.inspect}") unless SUPPORTED_PARSERS.include?(parser_sym)
        @parser_name = parser_sym
      end
      
      # Get the name of the current parser.
      def parser_name
        @parser_name ||= :rexml
      end
      
      # Parse the document specified in io. This can be either a Stream, URI, Pathname, or String. If it is a String,
      # it can either be a XML document, file system path, or URI. The parser will figure it out. If a block is given,
      # it will be yielded to with each node as it is parsed.
      def parse (io, &block)
        close_stream = false
        if io.is_a?(String)
          if io.include?('<') and io.include?('>')
            io = StringIO.new(io)
          else
            io = open(io)
          end
          close_stream = true
        elsif io.is_a?(Pathname)
          io = io.open
          close_stream = true
        elsif io.is_a?(URI)
          io = io.open
          close_stream = true
        end

        begin
          parser = parser_class(parser_name).new(&block)
          parser.parse_stream(io)
          return parser.root
        ensure
          io.close if close_stream
        end
      end
    
      protected
      
      def parser_class (class_symbol)
        @loaded_parsers ||= {}
        klass = @loaded_parsers[class_symbol]
        unless klass
          require File.expand_path(File.join(File.dirname(__FILE__), 'parser', "#{class_symbol}_parser"))
          class_name = "#{class_symbol.to_s.capitalize}Parser"
          klass = const_get(class_name)
          @loaded_parsers[class_symbol] = klass
        end
        return klass
      end
    end
  end
end
