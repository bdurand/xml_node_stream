# frozen_string_literal: true

require "spec_helper"

RSpec.describe XmlNodeStream::HttpStream do
  let(:url) { "http://example.com/test.xml" }
  let(:uri) { URI.parse(url) }
  let(:xml_content) { "<root><child>Hello World</child></root>" }

  describe "#read" do
    it "should read the entire response body when no length is specified" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      content = stream.read

      expect(content).to eq(xml_content)
    end

    it "should read a specific length of bytes" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      content = stream.read(10)

      expect(content).to eq("<root><chi")
      expect(content.bytesize).to eq(10)
    end

    it "should read remaining content after partial read" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      first_chunk = stream.read(10)
      remaining = stream.read

      expect(first_chunk).to eq("<root><chi")
      expect(remaining).to eq("ld>Hello World</child></root>")
    end

    it "should support the outbuf parameter" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      buffer = +""
      result = stream.read(10, buffer)

      expect(result).to eq("<root><chi")
      expect(buffer).to eq("<root><chi")
      expect(result.object_id).to eq(buffer.object_id)
    end

    it "should return nil when reading past EOF with length specified" do
      stub_request(:get, url).to_return(body: "short")

      stream = XmlNodeStream::HttpStream.new(uri)
      stream.read # Read all
      result = stream.read(10)

      expect(result).to be_nil
    end

    it "should handle chunked responses" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      chunks = []
      chunks << stream.read(10)
      chunks << stream.read(10)
      chunks << stream.read(10)
      chunks << stream.read

      expect(chunks.join).to eq(xml_content)
    end
  end

  describe "#gets" do
    let(:multiline_content) { "line1\nline2\nline3" }

    it "should read a line ending with newline" do
      stub_request(:get, url).to_return(body: multiline_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      line = stream.gets

      expect(line).to eq("line1\n")
    end

    it "should read multiple lines" do
      stub_request(:get, url).to_return(body: multiline_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      lines = []
      lines << stream.gets
      lines << stream.gets
      lines << stream.gets

      expect(lines).to eq(["line1\n", "line2\n", "line3"])
    end

    it "should handle custom separator" do
      stub_request(:get, url).to_return(body: "part1|part2|part3")

      stream = XmlNodeStream::HttpStream.new(uri)
      part1 = stream.gets("|")
      part2 = stream.gets("|")

      expect(part1).to eq("part1|")
      expect(part2).to eq("part2|")
    end

    it "should read all content when separator is nil" do
      stub_request(:get, url).to_return(body: multiline_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      content = stream.gets(nil)

      expect(content).to eq(multiline_content)
    end

    it "should return nil at EOF" do
      stub_request(:get, url).to_return(body: "single line")

      stream = XmlNodeStream::HttpStream.new(uri)
      stream.gets
      result = stream.gets

      expect(result).to be_nil
    end

    it "should return remaining content without separator at EOF" do
      stub_request(:get, url).to_return(body: "no newline at end")

      stream = XmlNodeStream::HttpStream.new(uri)
      line = stream.gets

      expect(line).to eq("no newline at end")
    end
  end

  describe "#eof?" do
    it "should return false before reading" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)

      expect(stream.eof?).to be false
    end

    it "should return true after reading all content" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      stream.read

      expect(stream.eof?).to be true
    end

    it "should return false when buffer has data" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      stream.read(5)

      expect(stream.eof?).to be false
    end
  end

  describe "#close" do
    it "should close the HTTP connection" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      stream.read(5)

      expect { stream.close }.not_to raise_error
    end

    it "should be safe to call multiple times" do
      stub_request(:get, url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      stream.close

      expect { stream.close }.not_to raise_error
    end
  end

  describe "HTTPS support" do
    let(:https_url) { "https://secure.example.com/test.xml" }
    let(:https_uri) { URI.parse(https_url) }

    it "should handle HTTPS URLs" do
      stub_request(:get, https_url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(https_uri)
      content = stream.read

      expect(content).to eq(xml_content)
    end
  end

  describe "error handling" do
    it "should handle network errors gracefully" do
      stub_request(:get, url).to_timeout

      stream = XmlNodeStream::HttpStream.new(uri)

      expect { stream.read }.to raise_error(Timeout::Error)
    end

    it "should raise an error for HTTP error responses" do
      stub_request(:get, url).to_return(status: 404, body: "Not Found")

      stream = XmlNodeStream::HttpStream.new(uri)

      expect { stream.read }.to raise_error(XmlNodeStream::HttpError, /404/) do |error|
        expect(error.response.code).to eq("404")
      end
    end
  end

  describe "redirects" do
    it "should follow redirects" do
      redirect_url = "http://example.com/redirected.xml"
      stub_request(:get, url).to_return(status: 302, headers: {"Location" => redirect_url})
      stub_request(:get, redirect_url).to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      content = stream.read

      expect(content).to eq(xml_content)
    end

    it "should follow relative redirects" do
      stub_request(:get, url).to_return(status: 301, headers: {"Location" => "/moved.xml"})
      stub_request(:get, "http://example.com/moved.xml").to_return(body: xml_content)

      stream = XmlNodeStream::HttpStream.new(uri)
      content = stream.read

      expect(content).to eq(xml_content)
    end

    it "should raise an error when there are too many redirects" do
      stub_request(:get, url).to_return(status: 302, headers: {"Location" => url})

      stream = XmlNodeStream::HttpStream.new(uri)

      expect { stream.read }.to raise_error(XmlNodeStream::HttpError, /Too many redirects/)
    end

    it "should raise an error when a redirect has no location" do
      stub_request(:get, url).to_return(status: 302)

      stream = XmlNodeStream::HttpStream.new(uri)

      expect { stream.read }.to raise_error(XmlNodeStream::HttpError, /without Location/)
    end
  end
end
