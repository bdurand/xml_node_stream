# frozen_string_literal: true

require "spec_helper"

RSpec.describe XmlNodeStream::Selector do
  let!(:root) { XmlNodeStream::Node.new("root") }
  let!(:child_1) { XmlNodeStream::Node.new("child", root) }
  let!(:child_2) { XmlNodeStream::Node.new("child", root) }
  let!(:grandchild_1) { XmlNodeStream::Node.new("grandchild", child_1, nil, "val1") }
  let!(:grandchild_2) { XmlNodeStream::Node.new("grandchild", child_1, nil, "val2") }
  let!(:grandchild_3) { XmlNodeStream::Node.new("grandchild", child_2, nil, "val3") }
  let!(:grandchild_4) { XmlNodeStream::Node.new("grandchild", child_2, nil, "val4") }
  let!(:great_grandchild) { XmlNodeStream::Node.new("grandchild", grandchild_1, nil, "val1.a") }

  it "should find child nodes with a specified name" do
    selector = XmlNodeStream::Selector.new("child")
    expect(selector.find(root)).to eq([child_1, child_2])
    selector = XmlNodeStream::Selector.new("./child")
    expect(selector.find(root)).to eq([child_1, child_2])
    selector = XmlNodeStream::Selector.new("nothing")
    expect(selector.find(root)).to eq([])
    expect(selector.find(child_1)).to eq([])
  end

  it "should find descendant nodes with a specified name" do
    selector = XmlNodeStream::Selector.new(".//grandchild")
    expect(selector.find(root)).to eq([grandchild_1, grandchild_2, great_grandchild, grandchild_3, grandchild_4])
    expect(selector.find(child_1)).to eq([grandchild_1, grandchild_2, great_grandchild])
    expect(selector.find(child_2)).to eq([grandchild_3, grandchild_4])
  end

  it "should find child nodes in a specified hierarchy" do
    selector = XmlNodeStream::Selector.new("child/grandchild")
    expect(selector.find(root)).to eq([grandchild_1, grandchild_2, grandchild_3, grandchild_4])
    selector = XmlNodeStream::Selector.new("child/nothing")
    expect(selector.find(root)).to eq([])
    expect(selector.find(child_1)).to eq([])
  end

  it "should find an node itself" do
    selector = XmlNodeStream::Selector.new(".")
    expect(selector.find(child_1)).to eq([child_1])
  end

  it "should find a parent node" do
    selector = XmlNodeStream::Selector.new("..")
    expect(selector.find(child_1)).to eq([root])
    expect(selector.find(root)).to eq([])
  end

  it "should find an node's value" do
    selector = XmlNodeStream::Selector.new("text()")
    expect(selector.find(child_1)).to eq([])
    expect(selector.find(grandchild_1)).to eq(["val1"])
    selector = XmlNodeStream::Selector.new("child/grandchild/text()")
    expect(selector.find(root)).to eq(["val1", "val2", "val3", "val4"])
  end

  it "should allow wildcards in the hierarchy" do
    selector = XmlNodeStream::Selector.new("*/grandchild")
    expect(selector.find(root)).to eq([grandchild_1, grandchild_2, grandchild_3, grandchild_4])
    expect(selector.find(child_1)).to eq([great_grandchild])
    expect(selector.find(child_2)).to eq([])
  end

  it "should find using full paths" do
    selector = XmlNodeStream::Selector.new("/root/child")
    expect(selector.find(root)).to eq([child_1, child_2])
    expect(selector.find(grandchild_1)).to eq([child_1, child_2])
  end

  it "should reject invalid XPath patterns" do
    expect { XmlNodeStream::Selector.new("") }.to raise_error(ArgumentError, /cannot be empty/)
    expect { XmlNodeStream::Selector.new(nil) }.to raise_error(ArgumentError, /cannot be empty/)
    expect { XmlNodeStream::Selector.new("child//") }.to raise_error(ArgumentError, /Invalid XPath pattern/)
    expect { XmlNodeStream::Selector.new("child///grandchild") }.to raise_error(ArgumentError, /Invalid XPath pattern/)
    expect { XmlNodeStream::Selector.new("child@attr") }.to raise_error(ArgumentError, /Invalid XPath pattern/)
    expect { XmlNodeStream::Selector.new("child[1]") }.to raise_error(ArgumentError, /Invalid XPath pattern/)
  end
end
