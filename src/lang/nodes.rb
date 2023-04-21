#!/usr/bin/env ruby

require_relative './operators.rb'


class BaseNode
  def initialize
    freeze
  end

  # evaluate
  def eval(scope)
    raise Error::NotImplemented.new
  end

  # optional method: `output'
  # evaluate str intended for output (not the same as to_s)

  # unwrap one step
  def unwrap
    return self  # default action
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

  # unwrap down to class if possible
  def unwrap_class(cls, incl_self=true)
    return self if (incl_self and self.class == cls)

    prev_value = self
    value = unwrap
    while value != prev_value and value.class != cls do
      prev_value = value
      value = value.unwrap
    end
    return value
  end

  def unwrap_classes(classes, incl_self=true)
    return self if (incl_self and classes.include?(self.class))

    prev_value = self
    value = unwrap
    while value != prev_value and classes.include?(value.class) do
      prev_value = value
      value = value.unwrap
    end
    return value
  end

  def unwrap_except_classes(classes)
    return self if (incl_self and classes.include?(self.class))

    prev_value = self
    value = unwrap
    while value != prev_value and !classes.include?(value.class) do
      prev_value = value
      value = value.unwrap
    end
    return value
  end
end

class TypeNode < BaseNode
  include BooleanOperators

  def initialize()
    super()
  end

  # optional method: `self.get_default'
  # create an instance where default values are used
  # (if values are applicable to the type, otherwise it will
  # likely just be a call to self.class.new)
  #def self.get_default
  #  raise Error::NotImplemented.new
  #end

  # evaluate
  def eval(scope)
    return self
  end

  def to_bytes
    return [0x0]  # false
  end

  def bool_eval?(scope)
    # coerce bytes into boolean result
    to_bytes.each {|e| return false if e != 0x0 }
    return true
  end

  # evaluate str intended for output (not the same as to_s)
  # optional method: `output'

  # class type
  def self.type
    raise Error::NotImplemented.new
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
    raise Error::NoSuchCast.new(from, self)
  end

  def ==(other)
    return self.class == other.class
  end

  def !=(other)
    return !(self == other)
  end
end


class ContainerTypeNode < TypeNode
  attr_reader :value

  def initialize(value)
    @value = value
    super()
  end

  def unwrap
    return @value
  end

  def method_missing(method_name, *args, &block)
    @value.public_send(method_name, *args, &block)
  end
end
