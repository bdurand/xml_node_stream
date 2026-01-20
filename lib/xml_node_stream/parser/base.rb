# frozen_string_literal: true

module XmlNodeStream
  class Parser
    # This is the base parser syntax that normalizes the SAX callbacks by providing a common interface
    # so that the actual parser implementation doesn't matter.
    module Base
      attr_reader :root

      # Initialize the parser.
      #
      # @yield [Node] each node as it is parsed
      def initialize(&block)
        @nodes = []
        @parse_block = block
        @root = nil
      end

      # Parse the input stream.
      #
      # @param io [IO] the input stream to parse
      # @return [void]
      # @raise [NotImplementedError] if the parser gem is not loaded
      def parse_stream(io)
        parser_name = self.class.name.split("::").last.sub("Parser", "").downcase
        gem_name = case parser_name
        when "nokogiri" then "nokogiri"
        when "libxml" then "libxml-ruby"
        when "rexml" then "rexml"
        else "unknown"
        end
        raise NotImplementedError.new("Parser gem not loaded: #{gem_name}. Install it with: gem install #{gem_name.split(" ").first}")
      end

      # Handle start element event.
      #
      # @param name [String] the element name
      # @param attributes [Hash] the element attributes
      # @return [void]
      # @api private
      def do_start_element(name, attributes)
        node = XmlNodeStream::Node.new(name, @nodes.last, attributes)
        @nodes.push(node)
      end

      # Handle end element event.
      #
      # @param name [String] the element name
      # @return [void]
      # @api private
      def do_end_element(name)
        node = @nodes.pop
        node.finish!
        @root = node if @nodes.empty?
        @parse_block&.call(node)
      end

      # Handle character data event.
      #
      # @param characters [String] the character data
      # @return [void]
      # @api private
      def do_characters(characters)
        @nodes.last.append(characters) unless @nodes.empty?
      end

      # Handle CDATA block event.
      #
      # @param characters [String] the CDATA content
      # @return [void]
      # @api private
      def do_cdata_block(characters)
        @nodes.last.append_cdata(characters) unless @nodes.empty?
      end
    end
  end
end
