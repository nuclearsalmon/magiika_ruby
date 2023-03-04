#!/usr/bin/env ruby

require 'singleton'
require_relative './operators.rb'


# Note: Defining a Node hierarchy like this is technically
# unnecessary thanks to duck typing, but it makes reading
# the relationships between different nodes easier.


class BaseNode
  # evaluate
  def eval
    raise MagiikaNotImplementedError.new
  end

  # optional method: `output'
  # evaluate str intended for output (not the same as to_s)

  # unwrap one step
  def unwrap
    return self
  end

  # unwrap down to class if possible
  def unwrap_to(cls)
    prev_value = self
    value = unwrap
    while value.class != cls or value != prev_value do
      prev_value = value
      value = value.unwrap
    end
    return value
  end

  # unwrap down to bottom if possible
  def unwrap_all
    prev_value = self
    value = unwrap
    while value != prev_value do
      prev_value = value
      value = value.unwrap
    end
    return value
  end
end


class TypeNode < BaseNode
  include BooleanOperators

  # create an instance where default values are used
  # (if values are applicable to the type, otherwise it will
  # likely just be a call to self.class.new)
  def self.get_default
    raise MagiikaNotImplementedError.new
  end

  # evaluate
  def eval
    return self
  end

  def to_bytes
    return [0x0]  # false
  end

  def bool_eval?
    # coerce bytes into boolean result
    to_bytes.each {|e| return false if e != 0x0 }
    return true
  end

  # evaluate str intended for output (not the same as to_s)
  # optional method: `output'

  # class type
  def self.type
    raise MagiikaNotImplementedError.new
  end

  # instance type (usually the same as the class type)
  def type
    return self.class.type
  end

  # expanded type, used for printing
  def expanded_type
    exp_begin = self.type
    exp_end = ""

    prev_value = self
    value = unwrap
    while value != prev_value do
      exp_begin += "(#{value.type}"
      exp_end += ")"
      prev_value = value
      value = value.unwrap
    end
    
    return exp_begin + exp_end
  end

  # cast to another type
  def cast(from)
    raise MagiikaNoSuchCastError.new(from, self)
  end

  def ==(other)
    return self.class == other.class
  end
end


class ContainerTypeNode < TypeNode
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def ==(other)
    if self.class == other.class then
      return true
    elsif other.respond_to?(:value) then
      val = @value.respond_to?(:unwrap_all) ? @value.unwrap : @value
      obj = other.value.respond_to?(:unwrap_all) ? other.value.unwrap : other.value
      return val == obj
    end

    return false
  end
end


class EmptyNode < TypeNode
  include Singleton

  def self.get_default
    return self.instance
  end

  def eval
    return self
  end

  def output
    return type
  end

  def self.type
    return "empty"
  end
end


class IntNode < ContainerTypeNode
  include NodeSafety
  include OperatorUtils
  include IncDecOperators
  include BitwiseOperators

  def initialize(value)
    if value.class != Integer then
      raise MagiikaMismatchedTypeError.new(value, self.type)
    end
    super(value)
  end

  def self.get_default
    return IntNode.new(0)
  end

  def bool_eval?
    return @value != 0
  end

  def output
    return @value.to_s
  end

  def self.type
    return "int"
  end

  def to_bytes
    return unsign(@value)
  end

  def +(obj=nil)
    return self if obj == nil

    verify_class(obj)
    return passthrough(:+, obj)
  end

  def -(obj=nil)
    return self.class.new(-@value) if obj == nil

    verify_class(obj)
    return passthrough(:-, obj)
  end

  def *(obj)
    verify_class(obj)
    return passthrough(:*, obj)
  end

  def /(obj)
    verify_class(obj)
    return passthrough(:/, obj)
  end

  def int_div(obj)
    verify_classes(obj, [FltNode, ])

    if !(obj.class <= ContainerTypeNode and self.class <= ContainerTypeNode) then
      raise MagiikaMismatchedTypeError("`#{self}', `#{obj}'.")
    end
    
    value = @value.to_f.public_send(:/, obj.value).truncate.to_i
    
    return self.class.new(value)
  end

  def %(obj)
    verify_class(obj)
    return passthrough(:%, obj)
  end
end


class FltNode < ContainerTypeNode
  include NodeSafety
  include OperatorUtils
  include IncDecOperators
  include BitwiseOperators

  def initialize(value)
    if value.class != Integer && value.class != Float then
      raise MagiikaMismatchedTypeError.new(value, self.type)
    end
    super(value)
  end

  def self.get_default
    return FltNode.new(0.0)
  end

  def bool_eval?
    return @value != 0.0
  end

  def output
    return @value.to_s
  end

  def self.type
    return "flt"
  end

  def to_bytes
    return unsign(@value)
  end

  def +(obj=nil)
    return self if obj == nil

    verify_classes(obj, [IntNode, ])
    value = passthrough_value(:+, obj).to_f
    return self.class.new(value)
  end

  def -(obj=nil)
    return self.class.new(-@value) if obj == nil

    verify_classes(obj, [IntNode, ])
    value = passthrough_value(:-, obj).to_f
    return self.class.new(value)
  end

  def *(obj)
    verify_classes(obj, [IntNode, ])
    value = passthrough_value(:*, obj).to_f
    return self.class.new(value)
  end

  def /(obj)
    verify_classes(obj, [IntNode, ])
    value = round_float(passthrough_value(:/, obj)).to_f
    return self.class.new(value)
  end

  def int_div(obj)
    verify_classes(obj, [IntNode, ])

    if !(obj.class <= ContainerTypeNode and self.class <= ContainerTypeNode) then
      raise MagiikaMismatchedTypeError("`#{self}', `#{obj}'.")
    end
    
    value = @value.to_f.public_send(:/, obj.value).truncate.to_f
    
    return self.class.new(value)
  end

  def %(obj)
    verify_classes(obj, [IntNode, ])
    return passthrough(:%, obj)
  end
end


class BoolNode < ContainerTypeNode
  include BitwiseOperators

  def initialize(value)
    if value.class != TrueClass and value.class != FalseClass then
      raise MagiikaMismatchedTypeError.new(value, self.type)
    end
    super(value)
  end

  def self.get_default
    return BoolNode.new(false)
  end

  def bool_eval?
    return @value
  end

  def output
    return @value.to_s
  end

  def self.type
    return "bool"
  end

  def to_bytes
    return [@value ? 0x0 : 0x1]
  end
end


class StrNode < ContainerTypeNode
  include NodeSafety
  include OperatorUtils
  include BitwiseOperators

  def initialize(value)
    if value.class != String then
      raise MagiikaMismatchedTypeError.new(value, self.type)
    end
    super(value)
  end

  def self.get_default
    return StrNode.new("")
  end

  def bool_eval?
    return @value != ""
  end

  def output
    return "\"" + @value.to_s + "\""
  end

  def self.type
    return "str"
  end

  def +(obj=nil)
    raise MagiikaUnsupportedOperationError.new("`+' `#{@value}'") if obj == nil

    verify_class()
    return passthrough(:+, obj)
  end

  def to_bytes
    # Unpack to 8-bit unsigned integers because signed integers are completely
    # goddamn unreadable to any normal person. 8-bit because
    # there's rarely any need for 16-bit here, this is most likely just
    return @value.unpack("C*")
  end
end


class MagicNode < ContainerTypeNode
  def initialize(value)
    if !(value.class < TypeNode) then
      raise MagiikaError.new("a MagicNode must be instansiated with a TypeNode.")
    elsif value.class <= MagicNode then
      raise MagiikaError.new("a MagicNode cannot contain another MagicNode.")
    end
    super(value)
  end

  def self.get_default
    return MagicNode.new(EmptyNode.get_default)
  end

  def eval
    return @value.eval
  end

  def bool_eval?
    return @value != EmptyNode.get_default
  end

  def output
    return @value.output
  end

  def unwrap
    return @value
  end

  def self.type
    return "magic"
  end
end


BUILT_IN_TYPES = {
  "empty" => EmptyNode,
  "bool" => BoolNode, 
  "int" => IntNode, 
  "flt" => FltNode,
  "str" => StrNode,
  "magic" => MagicNode,}


def is_valid_type(type)
  return BUILT_IN_TYPES[type] == nil
end


def type_to_node_class(type)
  cls = BUILT_IN_TYPES[type]
  raise MagiikaInvalidTypeError.new(type) if cls == nil
  return cls
end
