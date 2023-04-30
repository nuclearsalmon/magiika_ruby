#!/usr/bin/env ruby

require_relative '../extensions.rb'


class BoolNode < TypeNode
  include BitwiseOperators

  attr_reader :value

  def initialize(value)
    if value.class != TrueClass and value.class != FalseClass
      raise Error::MismatchedType.new(value, self.type)
    end

    @value = value

    freeze
  end

  def self.get_default
    return BoolNode.new(false)
  end

  def bool_eval?(scope)
    return @value
  end

  def output(scope)
    return @value.to_s
  end

  def self.type
    return 'bool'
  end

  def to_bytes
    return [@value ? 0x0 : 0x1]
  end

  def __eq(other, scope)
    return @value == other.bool_eval?(scope)
  end
end
