#!/usr/bin/env ruby

require_relative '../extensions.rb'


class StrNode < TypeNode
  include BitwiseOperators

  attr_reader :value

  def initialize(value)
    if value.class != String
      raise Error::MismatchedType.new(value, self.type)
    end

    @value = value
    
    freeze
  end

  def self.get_default
    return StrNode.new('')
  end

  def bool_eval?(scope)
    return @value != ''
  end

  def output(scope)
    return @value
  end

  def self.type
    return 'str'
  end

  def to_bytes
    # Unpack to 8-bit unsigned integers because signed integers are completely
    # goddamn unreadable to any normal person. 8-bit because
    # there's rarely any need for 16-bit here.
    return @value.unpack('C*')
  end

  def __add(other=nil, scope)
    if other == nil
      raise Error::UnsupportedOperation.new("`+' `#{@value}'")
    end

    other = other.eval(scope)
    
    if !other.respond_to?(:output)
      raise Error::UnsupportedOperation.new("`#{@value} + #{other}': rhs does not support output.")
    end

    return StrNode.new(@value + other.output)
  end
end
