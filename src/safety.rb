#!/usr/bin/env ruby


BN = 1000000000.0


module NodeSafety
  def verify_class(obj)
    if obj.class != self.class then
      raise MagiikaMismatchedTypeError.new(obj, self)
    end
  end

  def verify_classes(obj, ok_classes)
    if !(obj.class == self.class or ok_classes.include?(obj.class)) then
      raise MagiikaMismatchedTypeError.new(obj, self)
    end
  end

  def verify_type(obj)
    if obj.type != self.type then
      raise MagiikaMismatchedTypeError.new(obj, self)
    end
  end

  def verify_types(obj, ok_types)
    if obj.type != self.type or !ok_types.include?(obj.type) then
      raise MagiikaMismatchedTypeError.new(obj, self)
    end
  end
end

def round_float(value)
  value = (value*BN).round / BN if value != value.to_i
  return value
end