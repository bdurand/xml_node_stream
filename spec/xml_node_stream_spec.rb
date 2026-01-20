# frozen_string_literal: true

require "spec_helper"

RSpec.describe XmlNodeStream do
  it "should parse a document using the Parser.parse method" do
    block = lambda { |node| true }
    expect(XmlNodeStream::Parser).to receive(:parse).with("<xml/>", &block)
    XmlNodeStream.parse("<xml/>", &block)
  end
end
