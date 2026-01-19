# frozen_string_literal: true

require "spec_helper"

RSpec.describe XmlNodeStream::Parser do
  let(:text_xml_path) { File.expand_path(File.join(File.dirname(__FILE__), "..", "test.xml")) }

  it "should parse a document in a string" do
    validate_text_xml(XmlNodeStream::Parser.parse(File.read(text_xml_path)))
  end

  it "should parse a document in a file path string" do
    validate_text_xml(XmlNodeStream::Parser.parse(text_xml_path))
  end

  it "should parse a document in a file path" do
    validate_text_xml(XmlNodeStream::Parser.parse(Pathname.new(text_xml_path)))
  end

  it "should parse a document in a url string" do
    stub_request(:get, "http://test.host/test.xml").to_return(body: File.read(text_xml_path))
    URI.parse("http://test.host/test.xml")
    validate_text_xml(XmlNodeStream::Parser.parse("http://test.host/test.xml"))
  end

  it "should parse a document in a URI" do
    uri = URI.parse("http://test.host/test.xml")
    xml_content = File.read(text_xml_path)
    stub_request(:get, "http://test.host/test.xml").to_return(body: xml_content)
    validate_text_xml(XmlNodeStream::Parser.parse(uri))
  end

  it "should parse a document in a stream" do
    io = StringIO.new(File.read(text_xml_path))
    expect(io).not_to receive(:close)
    validate_text_xml(XmlNodeStream::Parser.parse(io))
  end

  it "should call a block with each element in a document" do
    nodes = []
    XmlNodeStream::Parser.parse(text_xml_path) do |node|
      nodes << node.path
    end
    expect(nodes).to eq(%w[
      /library/authors/author/name
      /library/authors/author
      /library/authors/author/name
      /library/authors/author
      /library/authors/author/name
      /library/authors/author
      /library/authors
      /library/collection/section/book/title
      /library/collection/section/book/author
      /library/collection/section/book/abstract
      /library/collection/section/book/volumes
      /library/collection/section/book
      /library/collection/section
      /library/collection/section/book/title
      /library/collection/section/book/author
      /library/collection/section/book/abstract
      /library/collection/section/book
      /library/collection/section/book/title
      /library/collection/section/book/author
      /library/collection/section/book/abstract
      /library/collection/section/book
      /library/collection/section/book/title
      /library/collection/section/book/alternate_title
      /library/collection/section/book/author
      /library/collection/section/book/abstract
      /library/collection/section/book
      /library/collection/section
      /library/collection
      /library
    ])
  end

  XmlNodeStream::Parser::SUPPORTED_PARSERS.each do |parser_name|
    context "with #{parser_name}" do
      before :all do
        @save_parser_name = XmlNodeStream::Parser.parser_name
        XmlNodeStream::Parser.parser_name = parser_name
      end

      after :all do
        XmlNodeStream::Parser.parser_name = @save_parser_name
      end

      it "should parse a document" do
        validate_text_xml(XmlNodeStream::Parser.parse(text_xml_path))
      rescue NotImplementedError
        pending("#{parser_name} is not installed for testing")
      end
    end
  end

  def validate_text_xml(root)
    validate(root, name: "library", children: ["authors", "collection"])

    validate(root.children[0], name: "authors", children: ["author"] * 3)
    validate(root.children[0].children[0], name: "author", attributes: {"id" => "1"}, children: ["name"])
    validate(root.children[0].children[0].children[0], name: "name", value: "Edward Gibbon")
    validate(root.children[0].children[1], name: "author", attributes: {"id" => "2"}, children: ["name"])
    validate(root.children[0].children[1].children[0], name: "name", value: "Herman Melville")
    validate(root.children[0].children[2], name: "author", attributes: {"id" => "3"}, children: ["name"])
    validate(root.children[0].children[2].children[0], name: "name", value: "Jack London")

    validate(root.children[1], name: "collection", children: ["section"] * 2)
    history = root.children[1].children[0]
    fiction = root.children[1].children[1]

    validate(history, name: "section", attributes: {"id" => "100", "name" => "History"}, children: ["book"])
    validate(history.children[0], name: "book", attributes: {"id" => "1"}, children: ["title", "author", "abstract", "volumes"])
    validate(history.children[0].children[0], name: "title", value: "The Decline & Fall of the Roman Empire")
    validate(history.children[0].children[1], name: "author", value: nil, attributes: {"id" => "1"})
    validate(history.children[0].children[2], name: "abstract", value: "History of the fall of Rome.")
    validate(history.children[0].children[3], name: "volumes", value: "6")

    validate(fiction, name: "section", attributes: {"id" => "200", "name" => "Fiction"}, children: ["book"] * 3)
    validate(fiction.children[0], name: "book", attributes: {"id" => "2"}, children: ["title", "author", "abstract"])
    validate(fiction.children[0].children[0], name: "title", value: "Call of the Wild")
    validate(fiction.children[0].children[1], name: "author", value: nil, attributes: {"id" => "3"})
    validate(fiction.children[0].children[2], name: "abstract", value: "\n          A dog goes to Alaska.\n        ")
    validate(fiction.children[1], name: "book", attributes: {"id" => "3"}, children: ["title", "author", "abstract"])
    validate(fiction.children[1].children[0], name: "title", value: "White Fang")
    validate(fiction.children[1].children[1], name: "author", value: nil, attributes: {"id" => "3"})
    validate(fiction.children[1].children[2], name: "abstract", value: "Dogs, wolves, etc.")
    validate(fiction.children[2], name: "book", attributes: {"id" => "4"}, children: ["title", "alternate_title", "author", "abstract"])
    validate(fiction.children[2].children[0], name: "title", value: "Moby Dick")
    validate(fiction.children[2].children[1], name: "alternate_title", value: "The Whale")
    validate(fiction.children[2].children[2], name: "author", value: nil, attributes: {"id" => "2"})
    validate(fiction.children[2].children[3], name: "abstract", value: "A mad captain seeks a mysterious white whale.")
  end

  def validate(node, options)
    expect(node.name).to eq(options[:name])
    expect(node.attributes).to eq(options[:attributes] || {})
    expect(node.value).to eq(options.include?(:value) ? options[:value] : "")
    expect(node.children.collect { |c| c.name }).to eq(options[:children] || [])
  end
end
