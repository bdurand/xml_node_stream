begin
  require 'rexml/document'
  require 'rexml/streamlistener'
  
  module XmlNodeStream
    class Parser
      # Wrapper for the REXML SAX parser.
      class RexmlParser
        include REXML::StreamListener
        include Base

        def parse_stream (io)
          parser = REXML::Parsers::StreamParser.new(io, self)
          parser.parse
        end

        def tag_start (name, attributes)
          do_start_element(name, attributes)
        end

        def tag_end (name)
          do_end_element(name)
        end

        def text (content)
          do_characters(content)
        end

        def cdata (content)
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
