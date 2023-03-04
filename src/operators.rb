#!/usr/bin/env ruby
require_relative './utils.rb'


module OperatorUtils
  def passthrough_value(op, obj)
    if !(obj.class <= ContainerTypeNode and self.class <= ContainerTypeNode) then
      raise MagiikaMismatchedTypeError.new(obj, self.class)
    end
    
    return @value.public_send(op, obj.value)
  end

  def passthrough(op, obj)
    value = passthrough_value(op, obj)
    return self.class.new(value)
  end
end


module IncDecOperators
  def pre_inc
    @value += 1
    return self.clone
  end

  def pre_dec
    @value -= 1
    return self.clone
  end

  def post_inc
    copy = self.clone
    @value += 1
    return copy
  end

  def post_dec
    copy = self.clone
    @value -= 1
    return copy
  end
end


module BooleanOperators
  def and(other)
    return BoolNode.new(self.bool_eval? && other.bool_eval?)
  end

  def or(other)
    return BoolNode.new(self.bool_eval? || other.bool_eval?)
  end

  def nor(other)
    return BoolNode.new(!(self.bool_eval? || other.bool_eval?))
  end

  def nand(other)
    return BoolNode.new(!(self.bool_eval? && other.bool_eval?))
  end

  def xor(other)
    return BoolNode.new(self.bool_eval? ^ other.bool_eval?)
  end

  def xnor(other)
    # XNOR is simply equality on booleans
    return BoolNode.new(self.bool_eval? == other.bool_eval?)
  end
end


module BitwiseOperators
  include OperatorUtils
  
  def bitwise_and(other)
    self_bytes, other_bytes = 
      normalize_bin_arr_len(self.to_bytes, other.to_bytes)

    return self_bytes.zip(other_bytes).map{|l,r| unsign([l&r])}
  end

  def bitwise_or(other)
    self_bytes, other_bytes = 
      normalize_bin_arr_len(self.to_bytes, other.to_bytes)

    return self_bytes.zip(other_bytes).map{|l,r| unsign([l|r])}
  end

  def bitwise_nand(other)
    self_bytes, other_bytes = 
      normalize_bin_arr_len(self.to_bytes, other.to_bytes)
    
    return self_bytes.zip(other_bytes).map{|l,r| unsign([~(l&r)])}
  end

  def bitwise_nor(other=nil)
    if other == nil then
      self_bytes = self.to_bytes

      return self_bytes.map{|x| unsign([~x])}
    else
      return bitwise_nand(other)
    end
  end

  def bitwise_xor(other)
    self_bytes, other_bytes = 
      normalize_bin_arr_len(self.to_bytes, other.to_bytes)
    
    return self_bytes.zip(other_bytes).map{|l,r| unsign([l^r])}
  end

  def bitwise_xnor(other)  # same as xand
    self_bytes, other_bytes = 
      normalize_bin_arr_len(self.to_bytes, other.to_bytes)
    
    return self_bytes.zip(other_bytes).map{|l,r| unsign([~(l^r)])}
  end

  def bitwise_shift_left(r)
    self_bytes = self.to_bytes

    return self_bytes.map{|l| unsign([l<<r])}
  end

  def bitwise_shift_right(r)
    self_bytes = self.to_bytes

    return self_bytes.map{|l| unsign([l>>r])}
  end
end
