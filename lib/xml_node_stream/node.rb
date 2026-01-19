# frozen_string_literal: true

module XmlNodeStream
  # Representation of an XML node.
  class Node
    attr_reader :name, :parent
    attr_accessor :value

    # Create a new Node.
    #
    # @param name [String] the name of the node
    # @param parent [Node, nil] the parent node
    # @param attributes [Hash, nil] the node attributes
    # @param value [String, nil] the node value
    def initialize(name, parent = nil, attributes = nil, value = nil)
      @name = name
      @attributes = attributes
      @parent = parent
      @parent&.add_child(self)
      @value = value
    end

    # Release a node by removing it from the tree structure so that the Ruby garbage collector can reclaim the memory.
    # This method should be called after you are done with a node. After it is called, the node will be removed from
    # its parent's children and will no longer be accessible.
    #
    # @return [void]
    def release!
      @parent&.remove_child(self)
    end

    # Array of the child nodes of the node.
    #
    # @return [Array<Node>] the child nodes
    def children
      @children ||= []
    end

    # Array of all descendants of the node.
    #
    # @return [Array<Node>] all descendant nodes
    def descendants
      if children.empty?
        children
      else
        (children + children.collect { |child| child.descendants }).flatten
      end
    end

    # Array of all ancestors of the node.
    #
    # @return [Array<Node>] all ancestor nodes
    def ancestors
      if @parent
        [@parent] + @parent.ancestors
      else
        []
      end
    end

    # Get the attributes of the node as a hash.
    #
    # @return [Hash] the node attributes
    def attributes
      @attributes ||= {}
    end

    # Get the root element of the node tree.
    #
    # @return [Node] the root node
    def root
      @parent ? @parent.root : self
    end

    # Get the full XPath of the node.
    #
    # @return [String] the XPath of the node
    def path
      @path ||= if @parent
        "#{@parent.path}/#{@name}"
      else
        "/#{@name}"
      end
      @path
    end

    # Get the value of the node attribute with the given name.
    #
    # @param name [String] the attribute name
    # @return [String, nil] the attribute value
    def [](name)
      @attributes[name] if @attributes
    end

    # Set the value of the node attribute with the given name.
    #
    # @param name [String] the attribute name
    # @param val [String] the attribute value
    # @return [String] the attribute value
    def []=(name, val)
      attributes[name] = val
    end

    # Add a child node.
    #
    # @param node [Node] the child node to add
    # @return [void]
    def add_child(node)
      children << node
      node.instance_variable_set(:@parent, self)
    end

    # Remove a child node.
    #
    # @param node [Node] the child node to remove
    # @return [Node, nil] the removed node or nil
    def remove_child(node)
      if @children
        if @children.delete(node)
          node.instance_variable_set(:@parent, nil)
        end
      end
    end

    # Get the first child node.
    #
    # @return [Node, nil] the first child node or nil
    def first_child
      @children&.first
    end

    # Find the first node that matches the given XPath. See Selector for details.
    #
    # @param selector [String, Selector] the XPath selector
    # @return [Node, nil] the first matching node or nil
    def find(selector)
      select(selector).first
    end

    # Find all nodes that match the given XPath. See Selector for details.
    #
    # @param selector [String, Selector] the XPath selector
    # @return [Array<Node>] all matching nodes
    def select(selector)
      selector = selector.is_a?(Selector) ? selector : Selector.new(selector)
      selector.find(self)
    end

    # Append CDATA to the node value.
    #
    # @param text [String] the CDATA text to append
    # @return [void]
    def append_cdata(text)
      append(text, false)
    end

    # Append text to the node value. If strip_whitespace is true, whitespace at the beginning and end
    # of the node value will be removed.
    #
    # @param text [String] the text to append
    # @param strip_whitespace [Boolean] whether to strip whitespace
    # @return [void]
    def append(text, strip_whitespace = true)
      if text
        @value ||= +""
        @last_strip_whitespace = strip_whitespace
        text = text.lstrip if @value.length == 0 && strip_whitespace
        @value << text if text.length > 0
      end
    end

    # Called after end tag to ensure that whitespace at the end of the string is properly stripped.
    #
    # @return [void]
    # @api private
    def finish!
      @value.rstrip! if @value && @last_strip_whitespace
    end
  end
end
