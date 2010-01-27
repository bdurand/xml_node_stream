require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe XmlNodeStream do
  
  it "should parse a document using the Parser.parse method" do
    block = lambda{}
    XmlNodeStream::Parser.should_receive(:parse).with("<xml/>", &block)
    XmlNodeStream.parse("<xml/>", &block)
  end
  
end