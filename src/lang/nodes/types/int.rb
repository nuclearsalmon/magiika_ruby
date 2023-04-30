#!/usr/bin/env ruby

require_relative '../extensions.rb'


class IntNode < TypeNode
  include IncDecOperators
  include BitwiseOperators

  attr_reader :value

  def initialize(value)
    if value.class != Integer
      raise Error::MismatchedType.new(value, Integer)
    end

    @value = value
    super()
  end

  def self.get_default
    return IntNode.new(0)
  end

  def bool_eval?(scope)
    return @value != 0
  end

  def output(scope)
    return @value.to_s
  end

  def self.type
    return 'int'
  end

  def to_bytes
    return Utils.unsign([@value])
  end

  def __eq(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value == other.value)
  end

  def __gt(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value > other.value)
  end
  
  def __lt(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value < other.value)
  end
  
  def __gte(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value <= other.value)
  end
  
  def __lte(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value >= other.value)
  end

  def __add(other=nil, scope)
    return self if other == nil
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return IntNode.new((@value + other.value).to_i)
  end

  def __sub(other=nil, scope)
    return IntNode.new(-@value) if other == nil
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return IntNode.new((@value - other.value).to_i)
  end

  def __mult(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return IntNode.new((@value * other.value).to_i)
  end

  def __div(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return IntNode.new((@value / other.value).to_i)
  end

  def __idiv(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return IntNode.new((@value.to_f / other.value).truncate.to_i)
  end

  def __mod(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return IntNode.new((@value % other.value).to_i)
  end
end
