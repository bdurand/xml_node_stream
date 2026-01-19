# frozen_string_literal: true

begin
  require "nokogiri"

  module XmlNodeStream
    class Parser
      # Wrapper for the Nokogiri SAX parser.
      class NokogiriParser
        include Base

        # Parse the input stream using Nokogiri.
        #
        # @param io [IO] the input stream to parse
        # @return [void]
        def parse_stream(io)
          listener = Listener.new(self)
          parser = Nokogiri::XML::SAX::Parser.new(listener)
          parser.parse(io)
        end

        class Listener < Nokogiri::XML::SAX::Document
          # Initialize the Nokogiri listener.
          #
          # @param parser [NokogiriParser] the parser instance
          def initialize(parser)
            @parser = parser
          end

          # Handle Nokogiri start element callback.
          #
          # @param name [String] the element name
          # @param attributes [Array] the element attributes
          # @return [void]
          # @api private
          def start_element(name, attributes = [])
            attributes_hash = {}
            if attributes.first.is_a?(Array)
              # Newer style where attributes are passed as an array of arrays
              attributes.each do |k, v|
                attributes_hash[k] = v
              end
            else
              # Old style where attributes are passed as a flat array
              (attributes.size / 2).times { |i| attributes_hash[attributes[i * 2]] = attributes[(i * 2) + 1] }
            end
            @parser.do_start_element(name, attributes_hash)
          end

          # Handle Nokogiri end element callback.
          #
          # @param name [String] the element name
          # @return [void]
          # @api private
          def end_element(name)
            @parser.do_end_element(name)
          end

          # Handle Nokogiri character data callback.
          #
          # @param characters [String] the character data
          # @return [void]
          # @api private
          def characters(characters)
            @parser.do_characters(characters)
          end

          # Handle Nokogiri CDATA block callback.
          #
          # @param characters [String] the CDATA content
          # @return [void]
          # @api private
          def cdata_block(characters)
            @parser.do_cdata_block(characters)
          end
        end
      end
    end
  end
rescue LoadError
  module XmlNodeStream
    class Parser
      class NokogiriParser
        include Base
      end
    end
  end
end
