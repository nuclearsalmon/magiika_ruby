#!/usr/bin/env ruby

module OperatorUtils
  def verify_obj_type(obj)
    if obj.class != self.class then
      raise MagiikaMismatchedTypeError.new(obj, self)
    end
  end
end


module AddOperator
  include OperatorUtils

  # FIXME: should any of these actually ever be nil? and what about EmptyNode?
  def +(obj=nil)
    return self if obj == nil
    verify_obj_type(obj)

    return self.class.new(@value + obj.value)
  end
end


module JoinOperator
  include OperatorUtils

  def +(obj)
    raise MagiikaUnsupportedOperationError.new("unexpected nil") if obj == nil
    verify_obj_type(obj)

    return self.class.new(@value + obj.value)
  end
end


module SubtractOperator
  include OperatorUtils

  def -(obj=nil)
    return self.class.new(-@value) if obj == nil
    verify_obj_type(obj)

    return self.class.new(@value - obj.value)
  end
end


module MultiplyOperator
  include OperatorUtils

  def *(obj)
    verify_obj_type(obj)

    return self.class.new(@value * obj.value)
  end
end


module DivideOperator
  include OperatorUtils

  def /(obj)
    verify_obj_type(obj)

    return self.class.new(@value / obj.value)
  end
end
