# frozen_string_literal: true

begin
  require "bundler/setup"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end

require "bundler/gem_tasks"

task :verify_release_branch do
  unless `git rev-parse --abbrev-ref HEAD`.chomp == "main"
    warn "Gem can only be released from the main branch"
    exit 1
  end
end

Rake::Task[:release].prerequisites.prepend("verify_release_branch")

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: [:spec]

namespace :appraisal do
  desc "Update the appraisal gemfiles"
  task :update do
    Dir.glob("gemfiles/*.gemfile*") do |file|
      File.delete(file) if File.file?(file)
    end

    system "bundle exec appraisal generate" || abort("appraisal generate failed")

    Dir.glob("gemfiles/*.gemfile") do |file|
      puts "Locking #{file}"
      Bundler.with_unbundled_env do
        system(
          {
            "BUNDLE_GEMFILE" => file
          },
          "bundle", "lock", "--update"
        ) || abort("appraisal lock failed on #{file}")
      end
    end
  end
end

# Benchmark tasks

task benchmark: "benchmark:all"

namespace :benchmark do
  require_relative "benchmark/benchmark_helper"

  def benchmark_size
    ENV.fetch("SIZE", "5").to_i
  end

  desc "Run all benchmarks"
  task :all do
    [:nokogiri, :libxml, :rexml].each do |parser|
      Rake::Task["benchmark:#{parser}"].invoke
    end
  end

  [:nokogiri, :libxml, :rexml].each do |parser|
    desc "Compare streaming vs direct parser with #{parser.capitalize}"
    task parser do
      system({"SIZE" => benchmark_size.to_s}, "bundle", "exec", "rake", "benchmark:streaming:#{parser}") || exit(1)
      system({"SIZE" => benchmark_size.to_s}, "bundle", "exec", "rake", "benchmark:direct:#{parser}") || exit(1)
    end
  end

  namespace :streaming do
    desc "Benchmark streaming parser with Nokogiri"
    task :nokogiri do
      Benchmark::StreamingBenchmark.new(:nokogiri, size_mb: benchmark_size).execute
    end

    desc "Benchmark streaming parser with LibXML"
    task :libxml do
      Benchmark::StreamingBenchmark.new(:libxml, size_mb: benchmark_size).execute
    end

    desc "Benchmark streaming parser with REXML"
    task :rexml do
      Benchmark::StreamingBenchmark.new(:rexml, size_mb: benchmark_size).execute
    end
  end

  namespace :direct do
    desc "Benchmark direct parser with Nokogiri"
    task :nokogiri do
      Benchmark::DirectBenchmark.new(:nokogiri, size_mb: benchmark_size).execute
    end

    desc "Benchmark direct parser with LibXML"
    task :libxml do
      Benchmark::DirectBenchmark.new(:libxml, size_mb: benchmark_size).execute
    end

    desc "Benchmark direct parser with REXML"
    task :rexml do
      Benchmark::DirectBenchmark.new(:rexml, size_mb: benchmark_size).execute
    end
  end
end
