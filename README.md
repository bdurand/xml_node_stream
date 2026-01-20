# XML Node Stream

[![Continuous Integration](https://github.com/bdurand/xml_node_stream/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/xml_node_stream/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/xml_node_stream.svg)](https://badge.fury.io/rb/xml_node_stream)

This gem provides a very easy to use XML parser that provides the benefits of both stream parsing (i.e. SAX) and document parsing (i.e. DOM). In addition, it provides a unified parsing language for each of the major Ruby XML parsers (REXML, Nokogiri, and LibXML) so that your code doesn't have to be bound to a particular XML library.

## Usage

The primary purpose of this gem is to facilitate parsing large XML files (i.e. several megabytes in size). Often, reading these files into a document structure is not feasible because the whole document must be read into memory. Stream/SAX parsing solves this issue by reading in the file incrementally and providing callbacks for various events. This method can be quite painful to deal with for any sort of complex document structure.

This gem attempts to solve both of these issues by combining the best features of both. Parsing is performed by a stream parser which construct document style nodes and calls back to the application code with these nodes. When your application is done with a node, it can release it to free up memory and keep your heap from bloating.

In order to keep the interface simple and universal, only XML elements and text nodes are supported. XML processing instructions and comments will be ignored.

### Examples

Suppose we have file with every book in the world in it:

```xml
<books>
  <book isbn="123456">
    <title>Moby Dick</title>
    <author>Herman Melville</author>
    <categories>
      <category>Fiction</category>
      <category>Adventure</category>
    </categories>
  </book>
  <book isbn="98765643">
    <title>The Decline and Fall of the Roman Empire</title>
    <author>Edward Gibbon</author>
    <categories>
      <category>History</category>
      <category>Ancient</category>
    </categories>
  </book>
  ...
</books>
```

Reading the whole file into memory will cause problems as it bloats the heap with potentially gigabytes of data. This can be solved by using a streaming parser, but that code can be a pain to write and maintain.

We can use `XmlNodeStream` to use the best of both worlds. The file is streamed in to memory for processing and then released when we are done with it. But we get node data structures that can be used to interact with the document in a much simpler manner.

```ruby
XmlNodeStream.parse('/tmp/books.xml') do |node|
  if node.path == '/books/book'
    book = Book.new
    book.isbn = node['isbn']
    book.title = node.find('title').value
    book.author = node.find('author/text()')
    book.categories = node.select('categories/category/text()')
    book.save
    node.release!
  end
end
```

### Releasing Nodes

In the above example, what prevents memory bloat when parsing a large document is the call to node.release!. This call will remove the node from the node tree. The general practice is to look for the higher level nodes you are interested in and then release them immediately. If there are nodes you don't care about at all, those should be released immediately as well.

For example, if the XML document for the books also contained a large list of authors that we aren't using in our processing, we should still release the author nodes immediately to keep from bloating memory:

```xml
<library>
  <authors>
    <author id="1">
      <name>Herman Melville</name>
    </author>
    <author id="2">
      <name>Edward Gibbon</name>
    </author>
    ...
  </authors>
  <books>
    <book isbn="123456">
      ...
    </book>
    ...
  </books>
</library>
```

```ruby
XmlNodeStream.parse('/tmp/books.xml') do |node|
  if node.path == '/library/books/book'
    process_book(node)
    node.release!
  elsif node.path == '/library/authors/author'
    # we don't care about authors so release the nodes immediately
    node.release!
  end
end
```

A sample 77Mb XML document parsed into Nokogiri consumes over 800Mb of memory. Parsing the same document with XmlNodeStream and releasing top level nodes as they're processed uses less than 1Mb.

### XPath

You can use a subset of the XPath language to navigate nodes. The only parts of XPath implemented are the paths themselves and the text() function. The text() function is useful for getting the value of a node directly from the find or select methods without having to do a nil check on the nodes. For instance, in the above example we can get the name of an author with `node.find('author/text()')` instead of `node.find('author')&.value` or checking if the node exists before accessing its value.

The rest of the XPath language is not implemented since it is a programming language and there is really no need for it since we already have Ruby at our disposal which is far more powerful than XPath. See the Selector class for details.

## Perfomance

The performance of XmlNodeStream depends on which underlying XML parser is used. Generally, the native extension based parsers (Nokogiri and LibXML) will perform much better with out adding the overhead of XmlNodeStream. The pure Ruby REXML parser will perform much better with XmlNodeStream.

The main benefit of XmlNodeStream is memory efficiency when parsing large documents. By releasing nodes as they are processed, memory usage can be kept low even for very large documents. This reduces memory bloat and keeps your application process size consistent regardless of the size of the XML documents being processed which can be important in a long running server process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "xml_node_stream"
```

Then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install xml_node_stream
```

## Contributing

Open a pull request on [GitHub](https://github.com/bdurand/xml_node_stream).

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
