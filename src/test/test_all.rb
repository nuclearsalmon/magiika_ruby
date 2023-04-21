#!/usr/bin/env ruby

require_relative './testing_utils.rb'

# Automatically require all tests in this directory
Dir[File.join(File.dirname(__FILE__), "test_*.rb")].each { 
  |file|

  if file != __FILE__
    puts "requiring `#{file}'"
    require file
  end
}
