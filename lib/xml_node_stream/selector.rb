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
    def initialize (path)
      @parts = []
      path.gsub('//', '/%/').split('/').each do |part_path|
        part_matchers = []
        @parts << part_matchers
        or_paths = part_path.split('|')
        or_paths << "" if or_paths.empty?
        or_paths.each do |matcher_path|
          part_matchers << Matcher.new(matcher_path)
        end
      end
    end
    
    # Apply the selector to the current node. Note, if your path started with a /, it will be applied
    # to the root node.
    def find (node)
      matched = [node]
      @parts.each do |part_matchers|
        context = matched
        matched = []
        part_matchers.each do |matcher|
          matched.concat(matcher.select(context))
        end
        break if matched.empty?
      end
      return matched
    end
    
    # Match a partial path to a node.
    class Matcher
      def initialize (path)
        case path
        when 'text()'
          @extractor = lambda{|node| node.value}
        when '%'
          @extractor = lambda{|node| node.descendants}
        when '*'
          @extractor = lambda{|node| node.children}
        when '.'
          @extractor = lambda{|node| node}
        when '..'
          @extractor = lambda{|node| node.parent ? node.parent : []}
        when ''
          @extractor = lambda{|node| root = Node.new(nil); root.children << node.root; root}
        else
          @extractor = lambda{|node| node.children.select{|child| child.name == path}}
        end
      end
      
      # Select all nodes that match a partial path.
      def select (context_nodes)
        context_nodes.collect{|node| @extractor.call(node) if node.is_a?(Node)}.flatten
      end
    end
  end
end
