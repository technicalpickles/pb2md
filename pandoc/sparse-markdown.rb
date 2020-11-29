#!/usr/bin/env ruby
# Number all figures in a document and prefix the caption with "Figure".
require "bundler/setup"
require "pry-remote"
require "paru/filter"

Paru::Filter.run do 
  with "Span" do |span|
    binding.remote_pry
    span
  end
end