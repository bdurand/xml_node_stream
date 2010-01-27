require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'jeweler'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test xml_node_stream.'
Spec::Rake::SpecTask.new(:test) do |t|
  t.spec_files = 'spec/**/*_spec.rb'
end

desc 'Generate documentation for xml_node_stream.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options << '--title' << 'XML Node Stream' << '--line-numbers' << '--inline-source' << '--main' << 'README.rdoc'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Jeweler::Tasks.new do |gem|
  gem.name        = "xml_node_stream"
  gem.summary     = %Q{Simple XML parser wrapper that provides the benefits of stream parsing with the ease of using document nodes.}
  gem.email       = "brian@embellishedvisions.com"
  gem.homepage    = "http://github.com/bdurand/xml_node_stream"
  gem.authors     = ["Brian Durand"]
  
  gem.add_development_dependency('rspec', '>= 1.2.9')
end

Jeweler::GemcutterTasks.new
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end
