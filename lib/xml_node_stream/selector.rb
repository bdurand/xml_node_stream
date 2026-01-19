# frozen_string_literal: true

require "set"

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
    # @raise [ArgumentError] if the path is invalid
    def initialize(path)
      raise ArgumentError, "XPath pattern cannot be empty" if path.nil? || path.empty?

      @parts = tokenize_path(path)
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
        context_set = context.to_set
        matched = []

        part_matchers.each do |matcher|
          matched.concat(matcher.select(context, context_set))
        end

        break if matched.empty?
      end
      matched
    end

    private

    # Tokenize the XPath into parts using a simple lexer approach
    #
    # @param path [String] the XPath string to tokenize
    # @return [Array<Array<Matcher>>] array of matcher arrays
    # @raise [ArgumentError] if the path is malformed
    def tokenize_path(path)
      # Check for invalid patterns upfront
      raise ArgumentError, "Invalid XPath pattern: #{path} (triple slash not allowed)" if path.include?("///")

      parts = []
      i = 0
      path_length = path.length

      while i < path_length
        # Skip leading slash for absolute paths
        if i == 0 && path[i] == "/"
          parts << [Matcher.new("")]
          i += 1
          next
        end

        # Look for // (descendant operator)
        if i < path_length - 1 && path[i] == "/" && path[i + 1] == "/"
          i += 2
          # Check if there's a name after //
          name_match = path[i..].match(/\A([a-zA-Z_][\w-]*)/)
          if name_match
            parts << [Matcher.new("%#{name_match[1]}")]
            i += name_match[1].length
          elsif i >= path_length
            # // at end of path is invalid
            raise ArgumentError, "Invalid XPath pattern: #{path} (// cannot be at end)"
          else
            parts << [Matcher.new("%")]
          end
          next
        end

        # Regular path segment
        if path[i] == "/"
          i += 1
          next
        end

        # Extract the segment (until next / or end)
        segment_end = i
        in_parens = false
        while segment_end < path_length
          char = path[segment_end]
          if char == "("
            in_parens = true
          elsif char == ")"
            in_parens = false
          elsif char == "/" && !in_parens
            break
          elsif char == "[" || char == "@"
            raise ArgumentError, "Invalid XPath pattern: #{path} (predicates and attributes not supported)"
          end
          segment_end += 1
        end

        segment = path[i...segment_end]
        raise ArgumentError, "Invalid XPath pattern: #{path} (empty segment)" if segment.empty? && i > 0

        i = segment_end

        # Validate segment format
        unless segment.match?(/\A(\.\.?|\*|[a-zA-Z_][\w-]*|text\(\))(\|((\.\.?|\*|[a-zA-Z_][\w-]*|text\(\))))*\z/)
          raise ArgumentError, "Invalid XPath pattern: #{path} (invalid segment: #{segment})"
        end

        # Handle | (OR operator) within segment
        or_paths = segment.split("|")
        part_matchers = or_paths.map { |matcher_path| Matcher.new(matcher_path) }
        parts << part_matchers
      end

      parts
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
          lambda { |node, context_set| node.value unless node.value.nil? || node.value.empty? }
        when "%"
          lambda { |node, context_set| node.descendants }
        when "*"
          lambda { |node, context_set| node.children }
        when "."
          lambda { |node, context_set| node }
        when ".."
          lambda { |node, context_set| node.parent || [] }
        when ""
          lambda { |node, context_set|
            root = Node.new(nil)
            root.children << node.root
            root
          }
        when /^%(.+)$/  # descendants with name filter: %name
          name = $1
          lambda { |node, context_set| node.descendants.select { |d| d.name == name } }
        else
          lambda { |node, context_set|
            # Only return children matching the name
            # Don't include children that are already in the context
            node.children.select { |child| child.name == @path && !context_set&.include?(child) }
          }
        end
      end

      # Select all nodes that match a partial path.
      #
      # @param context_nodes [Array<Node>] the nodes to select from
      # @param context_set [Set<Node>, nil] optional set version of context_nodes for performance
      # @return [Array<Node>] the matching nodes
      def select(context_nodes, context_set = nil)
        context_set ||= context_nodes.to_set
        context_nodes.collect { |node| @extractor.call(node, context_set) if node.is_a?(Node) }.flatten.compact.uniq
      end
    end
  end
end
