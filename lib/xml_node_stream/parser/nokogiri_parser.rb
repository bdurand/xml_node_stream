begin
  require 'nokogiri'
  
  module XmlNodeStream
    class Parser
      # Wrapper for the Nokogiri SAX parser.
      class NokogiriParser
        include Base

        def parse_stream (io)
          listener = Listener.new(self)
          parser = Nokogiri::XML::SAX::Parser.new(listener)
          parser.parse(io)
        end
        
        class Listener < Nokogiri::XML::SAX::Document
          def initialize (parser)
            @parser = parser
          end
          
          def start_element (name, attributes = [])
            attributes_hash = {}
            (attributes.size / 2).times{|i| attributes_hash[attributes[i * 2]] = attributes[(i * 2) + 1]}
            @parser.do_start_element(name, attributes_hash)
          end

          def end_element (name)
            @parser.do_end_element(name)
          end

          def characters (characters)
            @parser.do_characters(characters)
          end

          def cdata_block (characters)
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