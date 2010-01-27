require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe XmlNodeStream::Node do
  
  it "should have a name" do
    node = XmlNodeStream::Node.new("tag")
    node.name.should == "tag"
  end
  
  it "should have attributes" do
    node = XmlNodeStream::Node.new("tag")
    node.attributes.should == {}
    node["attr1"].should == nil
    node = XmlNodeStream::Node.new("tag", nil, "attr1" => "val1", "attr2" => "val2")
    node.attributes.should == {"attr1" => "val1", "attr2" => "val2"}
    node["attr1"].should == "val1"
  end
  
  it "should have a value" do
    node = XmlNodeStream::Node.new("tag")
    node.value.should == nil
    node = XmlNodeStream::Node.new("tag", nil, nil, "value")
    node.value.should == "value"
  end
  
  it "should have a parent and children" do
    parent = XmlNodeStream::Node.new("tag")
    parent.parent.should == nil
    parent.children.should == []
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child")
    parent.add_child(child_2)
    parent.children.should == [child_1, child_2]
    child_1.parent.should == parent
    child_2.parent.should == parent
  end
  
  it "should be able to remove children" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    parent.children.should == [child_1, child_2]
    parent.remove_child(child_1)
    parent.children.should == [child_2]
    child_1.parent.should == nil
  end
  
  it "should release itself from its parent" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    parent.children.should == [child_1, child_2]
    child_1.release!
    parent.children.should == [child_2]
    child_1.parent.should == nil
  end
  
  it "should have ancestors" do
    parent = XmlNodeStream::Node.new("tag")
    child = XmlNodeStream::Node.new("child", parent)
    grandchild = XmlNodeStream::Node.new("grandchild", child)
    parent.ancestors.should == []
    child.ancestors.should == [parent]
    grandchild.ancestors.should == [child, parent]
  end
  
  it "should have descendants" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    grandchild_1 = XmlNodeStream::Node.new("grandchild", child_1)
    grandchild_2 = XmlNodeStream::Node.new("grandchild", child_1)
    parent.descendants.should == [child_1, child_2, grandchild_1, grandchild_2]
    child_1.descendants.should == [grandchild_1, grandchild_2]
    grandchild_1.descendants.should == []
  end
  
  it "should have a root node" do
    parent = XmlNodeStream::Node.new("tag")
    child = XmlNodeStream::Node.new("child", parent)
    grandchild = XmlNodeStream::Node.new("grandchild", child)
    parent.root.should == parent
    child.root.should == parent
    grandchild.root.should == parent
  end
  
  it "should have a path" do
    parent = XmlNodeStream::Node.new("tag")
    child = XmlNodeStream::Node.new("child", parent)
    grandchild = XmlNodeStream::Node.new("grandchild", child)
    parent.path.should == "/tag"
    child.path.should == "/tag/child"
    grandchild.path.should == "/tag/child/grandchild"
  end
  
  it "should be able to select related nodes using a selector" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    grandchild_1 = XmlNodeStream::Node.new("grandchild", child_1, nil, "val1")
    grandchild_2 = XmlNodeStream::Node.new("grandchild", child_1, nil, "val2")
    parent.select("nothing").should == []
    parent.select("child").should == [child_1, child_2]
    parent.select("child/grandchild").should == [grandchild_1, grandchild_2]
    parent.select("child/grandchild/text()").should == ["val1", "val2"]
    grandchild_1.select("../..").should == [parent]
  end
  
  it "should be able to find the first related node using a selector" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    grandchild_1 = XmlNodeStream::Node.new("grandchild", child_1, nil, "val1")
    grandchild_2 = XmlNodeStream::Node.new("grandchild", child_1, nil, "val2")
    parent.find("nothing").should == nil
    parent.find("child").should == child_1
    parent.find("child/grandchild").should == grandchild_1
    parent.find("child/grandchild/text()").should == "val1"
    grandchild_1.find("../..").should == parent
  end
  
  it "should append text which strips whitespace from the start and end of the value" do
    node = XmlNodeStream::Node.new("tag")
    node.append("   ")
    node.append(" \t\r\nhello ")
    node.append(" there\n")
    node.finish!
    node.value.should == "hello  there"
  end
  
  it "should append cdata which preserves all whitespace" do
    node = XmlNodeStream::Node.new("tag")
    node.append_cdata("   ")
    node.append(" \t\r\nhello ")
    node.append_cdata(" there\n")
    node.finish!
    node.value.should == "    \t\r\nhello  there\n"
  end
  
end
