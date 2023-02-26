#!/usr/bin/env ruby

require_relative '../magiika.rb'
require 'stringio'


FIXNUM_MAX = (2**(0.size * 8 -2) -1)
FIXNUM_MIN = -(2**(0.size * 8 -2))


# Shorthand function for creating a new Magiika environment
# and evaluating a string.
def parse_new(code)
  Magiika.new.parse(code)
end

def redirect_output(&block)
  output = StringIO.new
  begin
    $stdout = output
    block.call
  rescue
    $stdout = STDOUT
    raise
  ensure
    $stdout = STDOUT
  end

  return output.string
end
