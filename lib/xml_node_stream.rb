require File.expand_path(File.join(File.dirname(__FILE__), 'xml_node_stream', 'node'))
require File.expand_path(File.join(File.dirname(__FILE__), 'xml_node_stream', 'parser'))
require File.expand_path(File.join(File.dirname(__FILE__), 'xml_node_stream', 'selector'))

module XmlNodeStream
  # Helper method to parse XML. See Parser#parse for details.
  def self.parse (io, &block)
    Parser.parse(io, &block)
  end
end
