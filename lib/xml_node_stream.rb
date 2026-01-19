# frozen_string_literal: true

require "pathname"
require "uri"

require_relative "xml_node_stream/node"
require_relative "xml_node_stream/parser"
require_relative "xml_node_stream/selector"

module XmlNodeStream
  VERSION = File.read(File.expand_path("../VERSION", __dir__)).strip

  # Helper method to parse XML. See Parser#parse for details.
  #
  # @param io [IO, String, URI, Pathname] the input source to parse
  # @yield [Node] each node as it is parsed
  # @return [Node] the root node of the parsed document
  class << self
    def parse(io, &block)
      Parser.parse(io, &block)
    end
  end
end
