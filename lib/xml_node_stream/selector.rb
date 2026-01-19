# frozen_string_literal: true

module XmlNodeStream
  # Partial implementation of XPath selectors. Only abbreviated paths and the text() function are supported. The rest of XPath
  # is unecessary in the context of a Ruby application since XPath is also a programming language. If you really need an XPath
  # function, chances are you can just do it in the Ruby code.
  #
  # Example selectors:
  # * book - find all child book elements
  # * book/author - find all author elements that are children of the book child elements
  # * ../book - find all sibling book elements
  # * */author - find all author elements that are children of any child elements
  # * book//author - find all author elements that descendants at any level of book child elements
  # * .//author - find all author elements that are descendants of the current element
  # * /library/books/book - find all book elements with the full path /library/books/book
  # * author/text() - get the text values of all author child elements
  class Selector
    # Create a selector. Path should be an abbreviated XPath string.
    #
    # @param path [String] the XPath selector string
    def initialize(path)
      @parts = []
      # Handle // specially - instead of splitting into % and name, combine them
      path = path.gsub(/\/\/(\w+)/, '/%\1/')  # .//name becomes /%name/
      path = path.gsub("//", "/%/")           # // without name becomes /%/

      path.split("/").each do |part_path|
        part_matchers = []
        @parts << part_matchers
        or_paths = part_path.split("|")
        or_paths << "" if or_paths.empty?
        or_paths.each do |matcher_path|
          part_matchers << Matcher.new(matcher_path)
        end
      end
    end

    # Apply the selector to the current node. Note, if your path started with a /, it will be applied
    # to the root node.
    #
    # @param node [Node] the node to apply the selector to
    # @return [Array<Node>] the matching nodes
    def find(node)
      matched = [node]
      @parts.each do |part_matchers|
        context = matched
        matched = []

        part_matchers.each do |matcher|
          matched.concat(matcher.select(context))
        end

        break if matched.empty?
      end
      matched
    end

    # Match a partial path to a node.
    class Matcher
      # Create a new Matcher.
      #
      # @param path [String] the path pattern to match
      def initialize(path)
        @path = path
        @extractor = case path
        when "text()"
          lambda { |node, context_nodes = []| node.value unless node.value.nil? || node.value.empty? }
        when "%"
          lambda { |node, context_nodes = []| node.descendants }
        when "*"
          lambda { |node, context_nodes = []| node.children }
        when "."
          lambda { |node, context_nodes = []| node }
        when ".."
          lambda { |node, context_nodes = []| node.parent || [] }
        when ""
          lambda { |node, context_nodes = []|
            root = Node.new(nil)
            root.children << node.root
            root
          }
        when /^%(.+)$/  # descendants with name filter: %name
          name = $1
          lambda { |node, context_nodes = []| node.descendants.select { |d| d.name == name } }
        else
          lambda { |node, context_nodes = []|
            # Only return children matching the name
            # Don't include children that are already in the context
            node.children.select { |child| child.name == @path && !context_nodes.include?(child) }
          }
        end
      end

      # Select all nodes that match a partial path.
      #
      # @param context_nodes [Array<Node>] the nodes to select from
      # @return [Array<Node>] the matching nodes
      def select(context_nodes)
        context_nodes.collect { |node| @extractor.call(node, context_nodes) if node.is_a?(Node) }.flatten.compact.uniq
      end
    end
  end
end
