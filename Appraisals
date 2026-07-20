# frozen_string_literal: true

appraise "rexml_3" do
  gem "rexml", "~> 3.2"
  remove_gem "nokogiri"
  remove_gem "libxml-ruby"
end

appraise "nokogiri_1" do
  gem "nokogiri", "~> 1.11"
  remove_gem "rexml"
  remove_gem "libxml-ruby"
end

appraise "libxml_3" do
  gem "libxml-ruby", "~> 3.2"
  remove_gem "rexml"
  remove_gem "nokogiri"
end
