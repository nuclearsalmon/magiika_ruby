#!/usr/bin/env ruby


# ⭐ Module utilities
# ------------------------------------------------------------------------------

module OperatorUtils
  def __passthrough_value(op, obj)
    if !(obj.class <= ContainerTypeNode and self.class <= ContainerTypeNode)
      raise Error::MismatchedType.new(obj, self.class)
    end
    
    return self.value.public_send(op, obj.value)
  end

  def __passthrough(op, obj)
    value = passthrough_value(op, obj)
    return self.class.new(value)
  end
end


# ⭐ Extension modules
# ------------------------------------------------------------------------------

module IncDecOperators
  def __pre_inc(_)
    self.value += 1
    return self.clone
  end

  def __pre_dec(_)
    self.value -= 1
    return self.clone
  end

  def __post_inc(_)
    copy = self.clone
    self.value += 1
    return copy
  end

  def __post_dec(_)
    copy = self.clone
    self.value -= 1
    return copy
  end
end


module TypeEqualityOperators
  def __eq(other, _)
    return self.type == other.type
  end

  def __neq(other, _)
    return self.type != other.type
  end
end


module BooleanOperators
  def __and(other, scope)
    return BoolNode.new(self.bool_eval?(scope) && other.bool_eval?(scope))
  end

  def __or(other, scope)
    return BoolNode.new(self.bool_eval?(scope) || other.bool_eval?(scope))
  end

  def __nor(other, scope)
    return BoolNode.new(!(self.bool_eval?(scope) || other.bool_eval?(scope)))
  end

  def __nand(other, scope)
    return BoolNode.new(!(self.bool_eval?(scope) && other.bool_eval?(scope)))
  end

  def __xor(other, scope)
    return BoolNode.new(self.bool_eval?(scope) ^ other.bool_eval?(scope))
  end

  def __xnor(other, scope)
    # XNOR is simply equality on booleans
    return BoolNode.new(self.bool_eval?(scope) == other.bool_eval?(scope))
  end
end


module BitwiseOperators
  def __bitwise_and(other, _)
    self_bytes, other_bytes = \
      Utils.normalize_bin_arr_len(self.to_bytes, other.to_bytes)

    return self_bytes.zip(other_bytes).map{|l,r| Utils.unsign([l&r])}
  end

  def __bitwise_or(other, _)
    self_bytes, other_bytes = 
      Utils.normalize_bin_arr_len(self.to_bytes, other.to_bytes)

    return self_bytes.zip(other_bytes).map{|l,r| Utils.unsign([l|r])}
  end

  def __bitwise_nand(other, _)
    self_bytes, other_bytes = 
      Utils.normalize_bin_arr_len(self.to_bytes, other.to_bytes)
    
    return self_bytes.zip(other_bytes).map{|l,r| Utils.unsign([~(l&r)])}
  end

  def __bitwise_nor(other=nil, _)
    if other == nil
      self_bytes = self.to_bytes

      return self_bytes.map{|x| Utils.unsign([~x])}
    else
      return bitwise_nand(other)
    end
  end

  def __bitwise_xor(other, _)
    self_bytes, other_bytes = 
      Utils.normalize_bin_arr_len(self.to_bytes, other.to_bytes)
    
    return self_bytes.zip(other_bytes).map{|l,r| Utils.unsign([l^r])}
  end

  def __bitwise_xnor(other, _)  # same as xand
    self_bytes, other_bytes = 
      Utils.normalize_bin_arr_len(self.to_bytes, other.to_bytes)
    
    return self_bytes.zip(other_bytes).map{|l,r| Utils.unsign([~(l^r)])}
  end

  def __bitwise_xnor(other, _)  # same as xnor
    return bitwise_xnor(other)
  end

  def __bitwise_shift_left(r, _)
    self_bytes = self.to_bytes

    return self_bytes.map{|l| Utils.unsign([l<<r])}
  end

  def __bitwise_shift_right(r, _)
    self_bytes = self.to_bytes

    return self_bytes.map{|l| Utils.unsign([l>>r])}
  end
end


# ⭐ Node extension base
# ------------------------------------------------------------------------------

class NodeExtension
  attr_reader :parent

  def __initialize(parent_node)
    @parent = parent_node
    
    if !(@parent.class <= TypeNode)
      raise Error::Magiika.new("Parent node must be a TypeNode.")
    end

    freeze
  end

  def __method_missing(method_name, *args, &block)
    raise Error::Magiika.new("`#{self}' does not extend support for `#{method_name}'.")
  end
end


class TypeNodeExtension < NodeExtension
  include TypeEqualityOperators
  include BooleanOperators
end
