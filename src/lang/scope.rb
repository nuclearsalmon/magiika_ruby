#!/usr/bin/env ruby

require 'set'


class Scope
  attr_reader :scopes

  def initialize
    @scopes = [{
      :@scope_type => :global,
      'bool' => MetaNode.new([:const], nil, BoolNode, true),
      'empty' => MetaNode.new([:const], nil, EmptyNode, true),
      'flt' => MetaNode.new([:const], nil, FltNode, true),
      'int' => MetaNode.new([:const], nil, IntNode, true),
      'str' => MetaNode.new([:const], nil, StrNode, true),
    }]
  end

  SEPARATOR_SCOPE_SLICE = {:@scope_type => :"---"   }.freeze

  # ⭐ PROTECTED
  # --------------------------------------------------------
  protected

  INCL_SCOPE_FILTER = Set[
    :cls_base,
    :cls_inst,
    :cls_init
  ].freeze

  # access_scope
  #  name     (string)  : Key.
  #  value    (any/nil) : Value to assign to key.
  #  mode     (symbol)  : The mode to operate in.
  #  - `:default`       :  Error if  already defined,
  #                         do not replace.
  #                         Does nothing when `value=nil`.
  #  - `:replace`       :  Replace if already defined.
  #                         Errors when `value=nil`.
  #  - `:retrieve`      :  Return value if already defined,
  #                         do not replace.
  #                         Errors when `value=nil`.
  #  - `:push`          :  Push to top of scopestack, error if
  #                         already defined in top scopestack.
  def access_scope(name,
                   value=nil,
                   mode=:default)
    if mode == :push
      raise Error::Magiika.new("Push mode requires a value.") if value == nil
      raise Error::AlreadyDefined.new(name) if @scopes[-1][name] != nil
      @scopes[-1][name] = value
      return value
    end

    if value == nil and mode != :default
      raise Error::Magiika.new(
        "Retrieval only uses the `:default` mode. Requested mode: `#{mode}`")
    end

    i = @scopes.length - 1
    filter_scopes = false
    while i >= 0
      scope = @scopes[i]

      if (filter_scopes && scope[:@scope_type] != :global \
          && !INCL_SCOPE_FILTER.include?(scope[:@scope_type]))
        nil # do nothing
      elsif scope[name] != nil
        if value != nil    # assignment
          case mode
          when :default
            raise Error::AlreadyDefined.new(name)
          when :replace
            scope[name] = value
            return value
          when :retrieve
            return scope[name]
          else
            raise Error::Magiika.new("Undefined mode: `#{mode}`")
          end
        else              # retrieval
          return scope[name]
        end
      elsif scope[:@scope_type] == :fn_call
        filter_scopes = true
      end
      i -= 1
    end

    # name not found
    if value != nil       # assignment
      @scopes[-1][name] = value
      return value
    else                  # retrieval
      raise Error::UndefinedVariable.new(name)
    end
  end

  def validate_meta(value)
    if !(value.class <= MetaNode)
      raise Error::UnsupportedOperation.new(\
        "Value must be a MetaNode. Value: `#{value}'")
    end
  end

  # ⭐ PUBLIC
  # --------------------------------------------------------
  public

  # ✨ Basics
  # --------------------------------------------------------

  def exist(name)
    begin
      access_scope(name)
    rescue Error::UndefinedVariable
      return false
    end
    return true
  end

  def set(name, value, mode=:default)
    # This is technically possible, 
    # but not the indended usage of the `set` function.
    raise Error::UnsupportedOperation.new("Attempted to set to nil.") if value == nil
    validate_meta(value)
    result = access_scope(name, value, mode)
    validate_meta(result)
    return result
  end

  def add(name, value)
    validate_meta(value)
    result = access_scope(name, value, :push)
    validate_meta(result)
    return result
  end

  def get(name)
    result = access_scope(name)
    validate_meta(result)
    return result
  end

  def get_smart_get(name, value)
    validate_meta(value)
    result = access_scope(name, value, :retrieve)
    validate_meta(result)
    return result
  end

  # ✨ Scope extension
  # --------------------------------------------------------

  def exec_scope(scope, &block)
    result = nil
    begin
      @scopes << SEPARATOR_SCOPE_SLICE

      @scopes << scope
      result = block.call
    ensure
      @scopes.delete_at(-1)

      @scopes.delete_at(-1)
    end
    return result
  end

  def exec_scopes(scopes, &block)
    result = nil
    begin
      @scopes << SEPARATOR_SCOPE_SLICE

      scopes.each {|scope| @scopes << scope}
      result = block.call
    ensure
      scopes.each {@scopes.delete_at(-1)}

      @scopes.delete_at(-1)
    end
    return result
  end


  # ✨ Section
  # --------------------------------------------------------

  # section_set
  #  name   (string)  : Section head key.
  #  key    (any/nil) : Section item key.
  #  value  (any/nil) : Section item value.
  #  mode   (symbol)  : The mode to operate in.
  #  - `:default`     :  Error if  already defined,
  #                       do not replace.
  #                       Does nothing when `value=nil`.
  #  - `:replace`     :  Replace if already defined.
  #                       Errors when `value=nil`.
  #  - `:retrieve`    :  Return value if already defined,
  #                       do not replace.
  #                       Errors when `value=nil`.
  def section_set(name, key, definition=nil, mode=:default)
    validate_meta(definition) if definition != nil

    if mode == :push
      if @scopes[-1][name] == nil
        @scopes[-1][name] = Hash.new
      elsif @scopes[-1][name].class == Hash
        if @scopes[-1][name][key] != nil
          raise Error::AlreadyDefined.new(key)
        end
      else
        raise Error::MismatchedType.new(@scopes[-1][name], Hash)
      end
      @scopes[-1][name][key] = definition
      return definition
    end

    section = access_scope(name, Hash.new, :retrieve)
    raise Error::MismatchedType.new(section, Hash) if !section.class == Hash

    if key == nil             # section instead of section item
      if definition != nil
        raise Error::UnsupportedOperation.new("Section head retrieval with definition.")
      end
      if mode != :default
        raise Error::Magiika.new(
          "Section head retrieval only uses the `:default` mode. \
          Requested mode: `#{mode}`")
      end
      return section
    end

    if definition != nil    # assignment
      case mode
      when :default
        if section[key] != nil
          raise Error::AlreadyDefined.new("#{name}[#{key}]")
        end
        section[key] = definition
      when :replace
        section[key] = definition
      when :retrieve
        return section[key]
      else
        raise Error::Magiika.new("Undefined mode: `#{mode}`")
      end
    else              # retrieval
      if mode != :default
        raise Error::Magiika.new(
          "Definitionless section retrieval only uses the `:default` mode. \
          Requested mode: `#{mode}`")
      end

      item = section[key]
      raise Error::UndefinedVariable.new("#{name}[#{key}]") if item == nil
      return item
    end
  end

  def section_add(name, key, definition)
    return section_set(name, key, definition)
  end

  def section_get(name, key=nil)
    return section_set(name, key)
  end

  def section_smart_get(name, key, definition)
    return section_set(name, key, definition, mode=:retrieve)
  end

  def section_exists(name, key=nil)
    begin
      section_set(name, key)
    rescue Error::UndefinedVariable
      return false
    end
    return true
  end
end
