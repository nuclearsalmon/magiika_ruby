module Unwrapping
  # unwrap one step
  def unwrap
    return self  # default action
  end

  # unwrap down to bottom if possible
  def unwrap_all
    prev_value = self
    value = unwrap()
    while value != prev_value do
      prev_value = value
      value = value.unwrap()
    end
    return value
  end

  def unwrap_all_except_class(cls, incl_self=true)
    return self if (incl_self and self.class == cls)

    prev_value = self
    value = unwrap()
    while value != prev_value and value.class != cls do
      prev_value = value
      value = value.unwrap()
    end
    return value
  end

  def unwrap_all_except_classes(classes, incl_self=true)
    return self if (incl_self and classes.include?(self.class))

    prev_value = self
    value = unwrap()
    while value != prev_value and !classes.include?(value.class) do
      prev_value = value
      value = value.unwrap()
    end
    return value
  end

  def unwrap_only_class(cls, incl_self=false)
    return self if (incl_self and self.class != cls)

    prev_value = self
    value = unwrap()
    while value != prev_value and value.class == cls do
      prev_value = value
      value = value.unwrap()
    end
    return value
  end

  # unwrap down to classes if possible
  def unwrap_only_classes(classes, incl_self=true)
    return self if (incl_self and !classes.include?(self.class))

    prev_value = self
    value = unwrap()
    while value != prev_value and classes.include?(value.class) do
      prev_value = value
      value = value.unwrap()
    end
    return value
  end

  def unwrap_to_list(incl_self=false)
    element_list = incl_self ? [self] : []

    prev_value = self
    value = unwrap()
    while value != prev_value do
      prev_value = value
      value = value.unwrap()
      element_list << value
    end
    return element_list
  end

  def unwrap_classes_to_list(incl_self=false)
    class_list = incl_self ? [self.class] : []

    prev_value = self
    value = unwrap()
    while value != prev_value do
      prev_value = value
      value = value.unwrap()
      class_list << value.class
    end
    return class_list
  end

  def unwrap_contains_class?(cls, incl_self=true)
    return true if (incl_self and self.class == cls)

    prev_value = self
    value = unwrap()
    while value != prev_value do
      return true if value.class == cls
      prev_value = value
      value = value.unwrap()
    end
    return false
  end

  def unwrap_contains_classes?(classes, incl_self=true)
    return true if (incl_self and classes.include?(self.class))

    prev_value = self
    value = unwrap()
    while value != prev_value do
      return true if classes.include?(value.class)
      prev_value = value
      value = value.unwrap()
    end
    return false
  end
end