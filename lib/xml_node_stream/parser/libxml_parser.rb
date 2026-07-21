# frozen_string_literal: true

begin
  require "libxml-ruby"

  module XmlNodeStream
    class Parser
      # Wrapper for the LibXML SAX parser.
      class LibxmlParser
        include LibXML::XML::SaxParser::Callbacks
        include Base

        # Parse the input stream using LibXML.
        #
        # @param io [IO] the input stream to parse
        # @return [void]
        def parse_stream(io)
          context = LibXML::XML::Parser::Context.io(io)
          parser = LibXML::XML::SaxParser.new(context)
          parser.callbacks = self
          parser.parse
        end

        # Handle LibXML start element callback.
        #
        # @param name [String] the element name
        # @param attributes [Hash] the element attributes
        # @return [void]
        # @api private
        def on_start_element(name, attributes)
          do_start_element(name, attributes)
        end

        # Handle LibXML end element callback.
        #
        # @param name [String] the element name
        # @return [void]
        # @api private
        def on_end_element(name)
          do_end_element(name)
        end

        # Handle LibXML character data callback.
        #
        # @param characters [String] the character data
        # @return [void]
        # @api private
        def on_characters(characters)
          do_characters(characters)
        end

        # Handle LibXML CDATA block callback.
        #
        # @param characters [String] the CDATA content
        # @return [void]
        # @api private
        def on_cdata_block(characters)
          do_cdata_block(characters)
        end
      end
    end
  end
rescue LoadError
  module XmlNodeStream
    class Parser
      class LibxmlParser
        include Base
      end
    end
  end
end
