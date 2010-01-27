require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe XmlNodeStream::Selector do
  
  before :each do
    @root = XmlNodeStream::Node.new("root")
    @child_1 = XmlNodeStream::Node.new("child", @root)
    @child_2 = XmlNodeStream::Node.new("child", @root)
    @grandchild_1 = XmlNodeStream::Node.new("grandchild", @child_1, nil, "val1")
    @grandchild_2 = XmlNodeStream::Node.new("grandchild", @child_1, nil, "val2")
    @grandchild_3 = XmlNodeStream::Node.new("grandchild", @child_2, nil, "val3")
    @grandchild_4 = XmlNodeStream::Node.new("grandchild", @child_2, nil, "val4")
    @great_grandchild = XmlNodeStream::Node.new("grandchild", @grandchild_1, nil, "val1.a")
  end
  
  it "should find child nodes with a specified name" do
    selector = XmlNodeStream::Selector.new("child")
    selector.find(@root).should == [@child_1, @child_2]
    selector = XmlNodeStream::Selector.new("./child")
    selector.find(@root).should == [@child_1, @child_2]
    selector = XmlNodeStream::Selector.new("nothing")
    selector.find(@root).should == []
    selector.find(@child_1).should == []
  end
  
  it "should find descendant nodes with a specified name" do
    selector = XmlNodeStream::Selector.new(".//grandchild")
    selector.find(@root).should == [@grandchild_1, @grandchild_2, @grandchild_3, @grandchild_4, @great_grandchild]
    selector.find(@child_1).should == [@great_grandchild]
    selector.find(@child_2).should == []
  end
  
  it "should find child nodes in a specified hierarchy" do
    selector = XmlNodeStream::Selector.new("child/grandchild")
    selector.find(@root).should == [@grandchild_1, @grandchild_2, @grandchild_3, @grandchild_4]
    selector = XmlNodeStream::Selector.new("child/nothing")
    selector.find(@root).should == []
    selector.find(@child_1).should == []
  end
  
  it "should find an node itself" do
    selector = XmlNodeStream::Selector.new(".")
    selector.find(@child_1).should == [@child_1]
  end
  
  it "should find a parent node" do
    selector = XmlNodeStream::Selector.new("..")
    selector.find(@child_1).should == [@root]
    selector.find(@root).should == []
  end
  
  it "should find an node's value" do
    selector = XmlNodeStream::Selector.new("text()")
    selector.find(@child_1).should == [nil]
    selector.find(@grandchild_1).should == ["val1"]
    selector = XmlNodeStream::Selector.new("child/grandchild/text()")
    selector.find(@root).should == ["val1", "val2", "val3", "val4"]
  end
  
  it "should allow wildcards in the hierarchy" do
    selector = XmlNodeStream::Selector.new("*/grandchild")
    selector.find(@root).should == [@grandchild_1, @grandchild_2, @grandchild_3, @grandchild_4]
    selector.find(@child_1).should == [@great_grandchild]
    selector.find(@child_2).should == []
  end
  
  it "should find using full paths" do
    selector = XmlNodeStream::Selector.new("/root/child")
    selector.find(@root).should == [@child_1, @child_2]
    selector.find(@grandchild_1).should == [@child_1, @child_2]
  end

end
