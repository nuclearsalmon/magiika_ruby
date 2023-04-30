#!/usr/bin/env ruby

require_relative '../extensions.rb'


class FltNode < TypeNode
  include IncDecOperators
  include BitwiseOperators

  attr_reader :value

  def initialize(value)
    if value.class != Integer && value.class != Float
      raise Error::MismatchedType.new(value, self.type)
    end

    @value = value.to_f
    super()
  end

  def self.get_default
    return FltNode.new(0.0)
  end

  def bool_eval?(scope)
    return @value.to_f != 0.0
  end

  def output(scope)
    return @value.to_s
  end

  def self.type
    return 'flt'
  end

  def to_bytes
    return Utils.unsign([@value])
  end

  def __eq(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value.to_f == other.value.to_f)
  end

  def __gt(other, scope)
    other = other.eval(scope)
    
    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value.to_f > other.value.to_f)
  end
  
  def __lt(other, scope)
    other = other.eval(scope)
    
    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value.to_f < other.value.to_f)
  end
  
  def __gte(other, scope)
    other = other.eval(scope)
    
    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value.to_f <= other.value.to_f)
  end
  
  def __lte(other, scope)
    other = other.eval(scope)
    
    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return BoolNode.new(@value.to_f >= other.value.to_f)
  end

  def __add(other=nil, scope)
    return self if other == nil
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return FltNode.new((@value.to_f + other.value.to_f).to_f)
  end

  def __sub(other=nil, scope)
    return FltNode.new(-@value) if other == nil
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return FltNode.new((@value.to_f - other.value.to_f).to_f)
  end

  def __mult(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return FltNode.new((@value.to_f * other.value.to_f).to_f)
  end

  def __div(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return FltNode.new((@value.to_f / other.value.to_f).to_f)
  end

  def __idiv(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return FltNode.new((@value.to_f / other.value.to_f).truncate.to_i)
  end

  def __mod(other, scope)
    other = other.eval(scope)

    if !(other.class == IntNode or other.class == FltNode)
      raise Error::MismatchedType.new(other, [IntNode, FltNode])
    end

    return FltNode.new(@value.to_f % other.value.to_f)
  end
end
