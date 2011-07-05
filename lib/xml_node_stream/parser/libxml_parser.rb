begin
  require 'libxml'
  
  module XmlNodeStream
    class Parser
      # Wrapper for the LibXML SAX parser.
      class LibxmlParser
        include LibXML::XML::SaxParser::Callbacks
        include Base

        def parse_stream (io)
          context = LibXML::XML::Parser::Context.io(io)
          parser = LibXML::XML::SaxParser.new(context)
          parser.callbacks = self
          parser.parse
        end
    
        def on_start_element (name, attributes)
          do_start_element(name, attributes)
        end

        def on_end_element (name)
          do_end_element(name)
        end

        def on_characters (characters)
          do_characters(characters)
        end

        def on_cdata_block (characters)
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