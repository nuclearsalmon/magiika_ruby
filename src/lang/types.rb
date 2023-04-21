#!/usr/bin/env ruby

require 'singleton'
require_relative './operators.rb'


module TypeNodeSafety
  def verify_class(obj)
    if obj.class != self.class
      raise Error::MismatchedType.new(obj, self)
    end
  end

  def verify_classes(obj, ok_classes)
    if !(obj.class == self.class or ok_classes.include?(obj.class))
      raise Error::MismatchedType.new(obj, self)
    end
  end

  def verify_type(obj)
    if obj.type != self.type
      raise Error::MismatchedType.new(obj, self)
    end
  end

  def verify_types(obj, ok_types)
    if obj.type != self.type or !ok_types.include?(obj.type)
      raise Error::MismatchedType.new(obj, self)
    end
  end
end


class EmptyNode < TypeNode
  include Singleton

  def self.get_default
    return self.instance
  end

  def eval(scope)
    return self
  end

  def output(scope)
    return type
  end

  def self.type
    return "empty"
  end
end


class IntNode < ContainerTypeNode
  include TypeNodeSafety
  include OperatorUtils
  include IncDecOperators
  include BitwiseOperators

  def initialize(value)
    if value.class != Integer
      raise Error::MismatchedType.new(value, self.type)
    end
    super(value)
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
    return "int"
  end

  def to_bytes
    return Utils.unsign([@value])
  end

  def ==(other)
    obj = other.respond_to?(:value) ? other.value : other
    return @value.public_send('==', obj)
  end

  def !=(other)
    return !(self == other)
  end

  def ===(other)
    return self == other
  end

  def >(other)
    verify_classes(other, [FltNode, ])
    return BoolNode.new(passthrough_value(:>, other))
  end
  
  def <(other)
    verify_classes(other, [FltNode, ])
    return BoolNode.new(passthrough_value(:<, other))
  end
  
  def >=(other)
    verify_classes(other, [FltNode, ])
    return BoolNode.new(passthrough_value(:>=, other))
  end
  
  def <=(other)
    verify_classes(other, [FltNode, ])
    return BoolNode.new(passthrough_value(:<=, other))
  end

  def +(other=nil)
    return self if other == nil

    verify_class(other)
    return passthrough(:+, other)
  end

  def -(other=nil)
    return self.class.new(-@value) if other == nil

    verify_class(other)
    return passthrough(:-, other)
  end

  def *(other)
    verify_class(other)
    return passthrough(:*, other)
  end

  def /(other)
    verify_class(other)
    return passthrough(:/, other)
  end

  def int_div(other)
    verify_classes(other, [FltNode, ])

    if !(other.class <= ContainerTypeNode and self.class <= ContainerTypeNode)
      raise Error::MismatchedType.new("`#{self}', `#{other}'.")
    end
    
    value = @value.to_f.public_send(:/, other.value).truncate.to_i
    
    return self.class.new(value)
  end

  def %(other)
    verify_class(other)
    return passthrough(:%, other)
  end
end


class FltNode < ContainerTypeNode
  include TypeNodeSafety
  include OperatorUtils
  include IncDecOperators
  include BitwiseOperators

  def initialize(value)
    if value.class != Integer && value.class != Float
      raise Error::MismatchedType.new(value, self.type)
    end
    super(value)
  end

  def self.get_default
    return FltNode.new(0.0)
  end

  def bool_eval?(scope)
    return @value != 0.0
  end

  def output(scope)
    return @value.to_s
  end

  def self.type
    return "flt"
  end

  def to_bytes
    return Utils.unsign([@value])
  end

  def ==(other)
    obj = other.respond_to?(:value) ? other.value : other
    return @value.public_send('==', obj)
  end

  def !=(other)
    return !(self == other)
  end

  def ===(other)
    return self == other
  end

  def >(other)
    verify_classes(other, [IntNode, ])
    return BoolNode.new(passthrough_value(:>, other))
  end
  
  def <(other)
    verify_classes(other, [IntNode, ])
    return BoolNode.new(passthrough_value(:<, other))
  end
  
  def >=(other)
    verify_classes(other, [IntNode, ])
    return BoolNode.new(passthrough_value(:>=, other))
  end
  
  def <=(other)
    verify_classes(other, [IntNode, ])
    return BoolNode.new(passthrough_value(:<=, other))
  end

  def +(other=nil)
    return self if other == nil

    verify_classes(other, [IntNode, ])
    value = passthrough_value(:+, other).to_f
    return self.class.new(value)
  end

  def -(other=nil)
    return self.class.new(-@value) if other == nil

    verify_classes(other, [IntNode, ])
    value = passthrough_value(:-, other).to_f
    return self.class.new(value)
  end

  def *(other)
    verify_classes(other, [IntNode, ])
    value = passthrough_value(:*, other).to_f
    return self.class.new(value)
  end

  def /(other)
    verify_classes(other, [IntNode, ])
    value = Utils.round_float(passthrough_value(:/, other)).to_f
    return self.class.new(value)
  end

  def int_div(other)
    verify_classes(other, [IntNode, ])

    if !(other.class <= ContainerTypeNode and self.class <= ContainerTypeNode)
      raise Error::MismatchedType.new("`#{self}', `#{other}'.")
    end
    
    value = @value.to_f.public_send(:/, other.value).truncate.to_f
    
    return self.class.new(value)
  end

  def %(other)
    verify_classes(other, [IntNode, ])
    return passthrough(:%, other)
  end
end


class BoolNode < ContainerTypeNode
  include BitwiseOperators

  def initialize(value)
    if value.class != TrueClass and value.class != FalseClass
      raise Error::MismatchedType.new(value, self.type)
    end
    super(value)
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
    return "bool"
  end

  def to_bytes
    return [@value ? 0x0 : 0x1]
  end

  def ==(other)
    obj = other.respond_to?(:bool_eval?) ? other.bool_eval? : other
    return @value.public_send('==', obj)
  end

  def !=(other)
    return !(self == other)
  end

  def ===(other)
    return self == other
  end
end


class StrNode < ContainerTypeNode
  include TypeNodeSafety
  include OperatorUtils
  include BitwiseOperators

  def initialize(value)
    if value.class != String
      raise Error::MismatchedType.new(value, self.type)
    end
    super(value)
  end

  def self.get_default
    return StrNode.new("")
  end

  def bool_eval?(scope)
    return @value != ""
  end

  def output(scope)
    return @value
  end

  def self.type
    return "str"
  end

  def +(other=nil)
    raise Error::UnsupportedOperation.new("`+' `#{@value}'") if other == nil

    verify_class()
    return passthrough(:+, other)
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
    if !(value.class < TypeNode)
      raise Error::Magiika.new("a MagicNode must be instansiated with a TypeNode.")
    elsif value.class <= MagicNode
      raise Error::Magiika.new("a MagicNode cannot contain another MagicNode.")
    end
    super(value)
  end

  def self.get_default
    return MagicNode.new(EmptyNode.get_default)
  end

  def eval(scope)
    return @value.eval(scope)
  end

  def bool_eval?(scope)
    return @value != EmptyNode.get_default
  end

  def output(scope)
    return @value.output(scope)
  end

  def unwrap
    return @value
  end

  def self.type
    return "magic"
  end
end
