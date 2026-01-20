# frozen_string_literal: true

require "spec_helper"

RSpec.describe XmlNodeStream::Node do
  it "should have a name" do
    node = XmlNodeStream::Node.new("tag")
    expect(node.name).to eq("tag")
  end

  it "should have attributes" do
    node = XmlNodeStream::Node.new("tag")
    expect(node.attributes).to eq({})
    expect(node["attr1"]).to be_nil
    node = XmlNodeStream::Node.new("tag", nil, "attr1" => "val1", "attr2" => "val2")
    expect(node.attributes).to eq("attr1" => "val1", "attr2" => "val2")
    expect(node["attr1"]).to eq("val1")
  end

  it "should have a value" do
    node = XmlNodeStream::Node.new("tag")
    expect(node.value).to be_nil
    node = XmlNodeStream::Node.new("tag", nil, nil, "value")
    expect(node.value).to eq("value")
  end

  it "should have a parent and children" do
    parent = XmlNodeStream::Node.new("tag")
    expect(parent.parent).to be_nil
    expect(parent.children).to eq([])
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child")
    parent.add_child(child_2)
    expect(parent.children).to eq([child_1, child_2])
    expect(child_1.parent).to eq(parent)
    expect(child_2.parent).to eq(parent)
  end

  it "should be able to remove children" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    expect(parent.children).to eq([child_1, child_2])
    parent.remove_child(child_1)
    expect(parent.children).to eq([child_2])
    expect(child_1.parent).to be_nil
  end

  it "should release itself from its parent" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    expect(parent.children).to eq([child_1, child_2])
    child_1.release!
    expect(parent.children).to eq([child_2])
    expect(child_1.parent).to be_nil
  end

  it "should have ancestors" do
    parent = XmlNodeStream::Node.new("tag")
    child = XmlNodeStream::Node.new("child", parent)
    grandchild = XmlNodeStream::Node.new("grandchild", child)
    expect(parent.ancestors).to eq([])
    expect(child.ancestors).to eq([parent])
    expect(grandchild.ancestors).to eq([child, parent])
  end

  it "should have descendants" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    grandchild_1 = XmlNodeStream::Node.new("grandchild", child_1)
    grandchild_2 = XmlNodeStream::Node.new("grandchild", child_1)
    expect(parent.descendants).to eq([child_1, child_2, grandchild_1, grandchild_2])
    expect(child_1.descendants).to eq([grandchild_1, grandchild_2])
    expect(grandchild_1.descendants).to eq([])
  end

  it "should have a root node" do
    parent = XmlNodeStream::Node.new("tag")
    child = XmlNodeStream::Node.new("child", parent)
    grandchild = XmlNodeStream::Node.new("grandchild", child)
    expect(parent.root).to eq(parent)
    expect(child.root).to eq(parent)
    expect(grandchild.root).to eq(parent)
  end

  it "should have a path" do
    parent = XmlNodeStream::Node.new("tag")
    child = XmlNodeStream::Node.new("child", parent)
    grandchild = XmlNodeStream::Node.new("grandchild", child)
    expect(parent.path).to eq("/tag")
    expect(child.path).to eq("/tag/child")
    expect(grandchild.path).to eq("/tag/child/grandchild")
  end

  it "should be able to select related nodes using a selector" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    child_2 = XmlNodeStream::Node.new("child", parent)
    grandchild_1 = XmlNodeStream::Node.new("grandchild", child_1, nil, "val1")
    grandchild_2 = XmlNodeStream::Node.new("grandchild", child_1, nil, "val2")
    expect(parent.select("nothing")).to eq([])
    expect(parent.select("child")).to eq([child_1, child_2])
    expect(parent.select("child/grandchild")).to eq([grandchild_1, grandchild_2])
    expect(parent.select("child/grandchild/text()")).to eq(["val1", "val2"])
    expect(grandchild_1.select("../..")).to eq([parent])
  end

  it "should be able to find the first related node using a selector" do
    parent = XmlNodeStream::Node.new("tag")
    child_1 = XmlNodeStream::Node.new("child", parent)
    XmlNodeStream::Node.new("child", parent)
    grandchild_1 = XmlNodeStream::Node.new("grandchild", child_1, nil, "val1")
    XmlNodeStream::Node.new("grandchild", child_1, nil, "val2")
    expect(parent.find("nothing")).to be_nil
    expect(parent.find("child")).to eq(child_1)
    expect(parent.find("child/grandchild")).to eq(grandchild_1)
    expect(parent.find("child/grandchild/text()")).to eq("val1")
    expect(grandchild_1.find("../..")).to eq(parent)
  end

  it "should append text which strips whitespace from the start and end of the value" do
    node = XmlNodeStream::Node.new("tag")
    node.append("   ")
    node.append(" \t\r\nhello ")
    node.append(" there\n")
    node.finish!
    expect(node.value).to eq("hello  there")
  end

  it "should append cdata which preserves all whitespace" do
    node = XmlNodeStream::Node.new("tag")
    node.append_cdata("   ")
    node.append(" \t\r\nhello ")
    node.append_cdata(" there\n")
    node.finish!
    expect(node.value).to eq("    \t\r\nhello  there\n")
  end
end
