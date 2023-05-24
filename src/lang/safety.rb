#!/usr/bin/env ruby

require 'set'


module KeywordSafety
  RESTRICTED_KEYWORDS = Set.new(
    # Yes, this is somewhat hard to read, I'm well aware.
    # I wanted a way to raise an error on any accidental
    # duplicates, rather than just ignoring them.
    Proc.new {
      keywords = [
        'abst',
        'abstract',
        'bool',
        'break',
        'class',
        'cls',
        'const',
        'elif',
        'else',
        'empty',
        'false',
        'fin',
        'final',
        'flt',
        'fn',
        'func',
        'if',
        'int',
        'magic',
        'priv',
        'private',
        'prot',
        'protected',
        'pub',
        'public',
        'return',
        'self',
        'stat',
        'static',
        'str',
        'this',
        'true',
      ]

      duplicates = keywords.group_by(&:itself).keep_if{|_,e| e.length > 1}.keys
      
      if duplicates.length > 0
        raise Error::Magiika.new("Duplicate keywords defined: `#{duplicates}'")
      end

      next keywords
    }.call
  ).freeze

  def verify_keyword_not_restricted(keyword)
    if RESTRICTED_KEYWORDS.include?(keyword)
      raise Error::UnsupportedOperation.new("Restricted keyword #{keyword}")
    end
  end
  module_function :verify_keyword_not_restricted
end


module TypeSafety
  # ⭐ PRIVATE
  # ---------------------------------------------------------------------------
  private

  DEFAULT_BUILT_IN_TYPES = {
    'empty' => EmptyNode,
    'bool'  => BoolNode, 
    'int'   => IntNode, 
    'flt'   => FltNode,
    'str'   => StrNode,
  }.freeze

  EXTENDED_BUILT_IN_TYPES = {
    'class' => nil,
    'cls' => nil,
    'fn' => nil,
    'func' => nil,
    'this' => nil,
    'self' => nil,
  }.freeze


  # ⭐ PUBLIC
  # ---------------------------------------------------------------------------
  public

  # NEWGEN ------------------------------------------------- 

  def verify_is_a_type(obj)
    # Verify that it inherits from TypeNode
    if !obj.is_a?(TypeNode)
      raise Error::Magiika.new("Non-TypeNode objects cannot be used as a Type.")
    end

    # Determine type
    if !(obj.is_a?(ClassNode))
      if obj.is_a?(ClassInstanceNode)  # verify that it's not a ClassInstanceNode
        raise Error::Magiika.new("A class instance cannot be used as a Type.")
      elsif obj.instance_of?(Object)      # verify that it's not an Object instance
        raise Error::Magiika.new("An instance cannot be a Type.")
      end
    end
  end
  module_function :verify_is_a_type

  def obj_is_type?(obj, type_obj, ignore_type_meta=false)
    return true if type_obj.class == NilClass or type_obj.class == EmptyNode

    # checks if `obj' is of type `type_obj'

    if obj.is_a?(MetaNode)
      if type_obj.is_a?(MetaNode)
        return false if obj.const != type_obj.const
        return false if !type_obj.magic && obj.magic
        
        type_obj = type_obj.unwrap
      end
      obj = obj.unwrap
    elsif type_obj.is_a?(MetaNode)
      if ignore_type_meta
        type_obj = type_obj.unwrap
      else
        return false if type_obj.const
        return true if type_obj.magic
      end
    end
    
    if !obj.is_a?(TypeNode)
      raise Error::Magiika.new("Non-TypeNode object.")
    end

    if obj.is_a?(ClassNode) or obj.is_a?(ClassInstanceNode)
      if type_obj.class <= ClassNode or type_obj.class <= ClassInstanceNode
        return obj.type == type_obj.type
      end
    else
      # assume built-in type
      return obj.class.type == type_obj.type
    end

    return false
  end
  module_function :obj_is_type?

end