module XmlNodeStream
  class Parser
    # This is the base parser syntax that normalizes the SAX callbacks by providing a common interface
    # so that the actual parser implementation doesn't matter.
    module Base
      
      attr_reader :root
      
      def initialize (&block)
        @nodes = []
        @parse_block = block
        @root = nil
      end
      
      def parse_stream (io)
        raise NotImplementedError.new("could not load gem")
      end
      
      def do_start_element (name, attributes)
        node = XmlNodeStream::Node.new(name, @nodes.last, attributes)
        @nodes.push(node)
      end

      def do_end_element (name)
        node = @nodes.pop
        node.finish!
        @root = node if @nodes.empty?
        @parse_block.call(node) if @parse_block
      end

      def do_characters (characters)
        @nodes.last.append(characters) unless @nodes.empty?
      end

      def do_cdata_block (characters)
        @nodes.last.append_cdata(characters) unless @nodes.empty?
      end
    end
  end
end
