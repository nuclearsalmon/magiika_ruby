#!/usr/bin/env ruby

module NodeSafety
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
