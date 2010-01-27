module XmlNodeStream
  # Representation of an XML node.
  class Node
  
    attr_reader :name, :parent
    attr_accessor :value
      
    def initialize (name, parent = nil, attributes = nil, value = nil)
      @name = name
      @attributes = attributes
      @parent = parent
      @parent.add_child(self) if @parent
      @value = value
    end
    
    # Release a node by removing it from the tree structure so that the Ruby garbage collector can reclaim the memory.
    # This method should be called after you are done with a node. After it is called, the node will be removed from
    # its parent's children and will no longer be accessible.
    def release!
      @parent.remove_child(self) if @parent
    end
    
    # Array of the child nodes of the node.
    def children
      @children ||= []
    end
    
    # Array of all descendants of the node.
    def descendants
      if children.empty?
        return children
      else
        return (children + children.collect{|child| child.descendants}).flatten
      end
    end

    # Array of all ancestors of the node.
    def ancestors
      if @parent
        return [@parent] + @parent.ancestors
      else
        return []
      end
    end
    
    # Get the attributes of the node as a hash.
    def attributes
      @attributes ||= {}
    end
    
    # Get the root element of the node tree.
    def root
      @parent ? @parent.root : self
    end
  
    # Get the full XPath of the node.
    def path
      unless @path
        if @parent
          @path = "#{@parent.path}/#{@name}"
        else
          @path = "/#{@name}"
        end
      end
      return @path
    end
  
    # Get the value of the node attribute with the given name.
    def [] (name)
      return @attributes[name] if @attributes
    end
    
    # Set the value of the node attribute with the given name.
    def []= (name, val)
      attributes[name] = val
    end
  
    # Add a child node.
    def add_child (node)
      children << node
      node.instance_variable_set(:@parent, self)
    end
  
    # Remove a child node.
    def remove_child (node)
      if @children
        if @children.delete(node)
          node.instance_variable_set(:@parent, nil)
        end
      end
    end
    
    # Get the first child node.
    def first_child
      @children.first if @children
    end
    
    # Find the first node that matches the given XPath. See Selector for details.
    def find (selector)
      select(selector).first
    end
    
    # Find all nodes that match the given XPath. See Selector for details.
    def select (selector)
      selector = selector.is_a?(Selector) ? selector : Selector.new(selector)
      return selector.find(self)
    end
    
    # Append CDATA to the node value.
    def append_cdata (text)
      append(text, false)
    end
    
    # Append text to the node value. If strip_whitespace is true, whitespace at the beginning and end
    # of the node value will be removed.
    def append (text, strip_whitespace = true)
      if text
        @value ||= ''
        @last_strip_whitespace = strip_whitespace
        text = text.lstrip if @value.length == 0 and strip_whitespace
        @value << text if text.length > 0
      end
    end
    
    # Called after end tag to ensure that whitespace at the end of the string is properly stripped.
    def finish! #:nodoc
      @value.rstrip! if @value and @last_strip_whitespace
    end
  end
end
