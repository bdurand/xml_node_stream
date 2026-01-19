# frozen_string_literal: true

begin
  require "rexml/document"
  require "rexml/streamlistener"

  module XmlNodeStream
    class Parser
      # Wrapper for the REXML SAX parser.
      class RexmlParser
        include REXML::StreamListener
        include Base

        # Parse the input stream using REXML.
        #
        # @param io [IO] the input stream to parse
        # @return [void]
        def parse_stream(io)
          parser = REXML::Parsers::StreamParser.new(io, self)
          parser.parse
        end

        # Handle REXML tag start callback.
        #
        # @param name [String] the element name
        # @param attributes [Hash] the element attributes
        # @return [void]
        # @api private
        def tag_start(name, attributes)
          do_start_element(name, attributes)
        end

        # Handle REXML tag end callback.
        #
        # @param name [String] the element name
        # @return [void]
        # @api private
        def tag_end(name)
          do_end_element(name)
        end

        # Handle REXML text callback.
        #
        # @param content [String] the text content
        # @return [void]
        # @api private
        def text(content)
          do_characters(content)
        end

        # Handle REXML CDATA callback.
        #
        # @param content [String] the CDATA content
        # @return [void]
        # @api private
        def cdata(content)
          do_cdata_block(content)
        end
      end
    end
  end
rescue LoadError
  module XmlNodeStream
    class Parser
      class RexmlParser
        include Base
      end
    end
  end
end
