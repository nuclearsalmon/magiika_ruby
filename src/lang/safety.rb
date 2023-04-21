#!/usr/bin/env ruby


module KeywordSafety
  RESTRICTED_KEYWORDS = [
    "public",
    "pub",
    "protected",
    "prot",
    "private",
    "priv",
    "static",
    "stat",
    "abstract",
    "abst",
    "class",
    "cls",
    "this",
    "self",
    "empty",
    "true",
    "false",
    "bool",
    "int",
    "flt",
    "str",
    "magic",
  ].freeze

  def validate_accessor(access)
    if ![:public, :protected, :private].include?(access)
      raise Error::UnsupportedOperation.new("Unknown access: #{access}")
    end
  end
  module_function :validate_accessor

  def validate_keyword(keyword)
    if RESTRICTED_KEYWORDS.include?(keyword)
      raise Error::UnsupportedOperation.new("Restricted keyword #{keyword}")
    end
  end
  module_function :validate_keyword
end

module TypeSafety
  # ⭐ PRIVATE
  # ---------------------------------------------------------------------------
  private

  DEFAULT_BUILT_IN_TYPES = {
    "empty" => EmptyNode,
    "bool"  => BoolNode, 
    "int"   => IntNode, 
    "flt"   => FltNode,
    "str"   => StrNode,
    "magic" => MagicNode,
  }.freeze

  EXTENDED_BUILT_IN_TYPES = {
    "cls" => nil,
    "this" => nil,
    "self" => nil,
  }.freeze


  # ⭐ PUBLIC
  # ---------------------------------------------------------------------------
  public
  
  def valid_builtin_type?(type)
    return true if DEFAULT_BUILT_IN_TYPES[type] != nil
    return true if EXTENDED_BUILT_IN_TYPES[type] != nil
  end
  module_function :valid_builtin_type?

  def valid_type?(type, scope)
    return true if valid_builtin_type?(type)
    if scope.exist(type)
      obj = scope.get(type)
      if obj.class <= TypeNode
        if obj.type == type or obj.class.type == type
          return true
        end
      end
    end
    return false
  end
  module_function :valid_type?
  
  def builtin_cls_from_typename(type)
    cls = DEFAULT_BUILT_IN_TYPES[type]
    raise Error::InvalidType.new(type) if cls == nil
    return cls
  end
  module_function :builtin_cls_from_typename

  def builtin_obj_from_typename(type)
    cls = builtin_cls_from_typename(type)
    
    if !cls.respond_to?(:get_default)
      raise Error::UnsupportedOperation.new("No default option for `#{type}'")
    end

    return cls.get_default()
  end
  module_function :builtin_obj_from_typename

  def obj_from_typename(type, scope)
    begin
      return builtin_obj_from_typename(type)
    rescue Error::InvalidType
      nil
    end

    if scope.exist(type)
      obj = scope.get(type)
      if obj.class <= TypeNode
        if obj.type == type or obj.class.type == type
          return obj
        end
      end
    end
    raise Error::InvalidType.new("No type found matching `#{type}'.")
  end
  module_function :obj_from_typename

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
      elsif valid_builtin_type?(expected_type)
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