# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{xml_node_stream}
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Durand"]
  s.date = %q{2011-07-05}
  s.email = %q{brian@embellishedvisions.com}
  s.extra_rdoc_files = [
    "MIT_LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "MIT_LICENSE",
    "README.rdoc",
    "Rakefile",
    "lib/xml_node_stream.rb",
    "lib/xml_node_stream/node.rb",
    "lib/xml_node_stream/parser.rb",
    "lib/xml_node_stream/parser/base.rb",
    "lib/xml_node_stream/parser/libxml_parser.rb",
    "lib/xml_node_stream/parser/nokogiri_parser.rb",
    "lib/xml_node_stream/parser/rexml_parser.rb",
    "lib/xml_node_stream/selector.rb",
    "spec/node_spec.rb",
    "spec/parser_spec.rb",
    "spec/selector_spec.rb",
    "spec/spec_helper.rb",
    "spec/test.xml",
    "spec/xml_node_stream_spec.rb"
  ]
  s.homepage = %q{http://github.com/bdurand/xml_node_stream}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Simple XML parser wrapper that provides the benefits of stream parsing with the ease of using document nodes.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 2.0.0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 2.0.0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 2.0.0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
  end
end

