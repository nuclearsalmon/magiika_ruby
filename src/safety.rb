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

module KeywordSafety
  def validate_accessor(access)
    if ![:public, :protected, :private].contains?(access)
      raise Error::Magiika.new("Unknown access: #{access}")
    end
  end
  module_function :validate_accessor
end

module TypeCheckSafety
  def type_conforms?(obj, expected_type, scope)
    raise Error::MismatchedType.new(obj, TypeNode) if !(obj.class <= TypeNode)

    return true if expected_type == "magic"

    if obj.class.type == "cls"
      if expected_type == "self" or expected_type == "this"
        self_obj = scope.get("self")
        if self_obj.class <= TypeNode and self_obj.class.type == "cls"
          return self_obj.type == obj.type
        else
          return false
        end
      elsif expected_type == "cls"
        return true
      elsif TypeUtils.valid_type?(expected_type)
        return false
      else
        resolved_obj = scope.get(expected_type)
        if resolved_obj.class <= TypeNode and resolved_obj.class.type == "cls"
          return resolved_obj.type == obj.type
        else
          return false
        end
      end
    else  # if obj is not a class
      return obj.type == expected_type
    end

    raise Error::Magiika.new("Not supposed to reach here. There's a bug.")
  end
  module_function :type_conforms?
end