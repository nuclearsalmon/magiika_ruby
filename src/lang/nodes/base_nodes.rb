#!/usr/bin/env ruby

require_relative './unwrapping.rb'
require_relative './extensions.rb'


class BaseNode
  include Unwrapping

  # evaluate
  def eval(scope)
    raise Error::NotImplemented.new
  end

  # optional method: `output'
  # evaluate str intended for output (not the same as to_s)
end


class TypeNode < BaseNode
  # optional method: `self.get_default'
  # create an instance where default values are used
  # (if values are applicable to the type, otherwise it will
  # likely just be a call to self.class.new)
  #def self.get_default
  #  raise Error::NotImplemented.new
  #end

  # evaluate
  def eval(scope)
    return self   # default to returning self, used to stop unwrapping loop.
  end

  def to_bytes
    return [0x0]  # false
  end

  def bool_eval?(scope)
    # coerce bytes into boolean result
    to_bytes.each {|e| return false if e != 0x0 }
    return true
  end

  # optional method: `output'
  # evaluate str intended for output (not the same as to_s)

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

  # ✨ Extensions
  # --------------------------------------------------------
  
  def __eq(other, _)
    return BoolNode.new(false)
  end

  def __neq(other, _)
    return BoolNode.new(true)
  end

  include BooleanOperators

  def ext_call(method_name, *args, &block)
    extended_method_name = ('__' + method_name.to_s).to_sym
    
    if self.respond_to?(extended_method_name)
      self.send(extended_method_name, *args, &block)
    else
      raise Error::Magiika.new("`#{self.class}' does not extend support for `#{method_name}'.")
    end
  end
end

class ContainerTypeNode < TypeNode
  attr_accessor :value
  
  def initialize(value)
    @value = value
    super()
  end
end
