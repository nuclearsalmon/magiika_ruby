#!/usr/bin/env ruby

require_relative '../magiika.rb'


FIXNUM_MAX = (2**(0.size * 8 -2) -1)
FIXNUM_MIN = -(2**(0.size * 8 -2))


# Shorthand function for creating a new Magiika environment
# and evaluating a string.
def parse_new(code)
  Magiika.new.parse(code)
end
