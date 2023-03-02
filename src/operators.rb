#!/usr/bin/env ruby


module OperatorUtils
  def passthrough_value(op, obj)
    if !(obj.class <= ContainerTypeNode and self.class <= ContainerTypeNode) then
      raise MagiikaMismatchedTypeError("`#{self}', `#{obj}'.")
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
