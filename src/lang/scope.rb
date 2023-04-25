#!/usr/bin/env ruby


class Scope
  attr_reader :scopes

  def initialize
    @scopes = [{:@scope_type => :global}]
  end

  SEPARATOR_SCOPE_SLICE = {:@scope_type => :"---"}.freeze
  FN_QUERY_SCOPE_SLICE  = {:@scope_type => :fn_query}.freeze

  # ⭐ PROTECTED
  # --------------------------------------------------------
  protected

  def verify_not_const(scope, name) 
    if scope[name].class <= TypeNode
      p scope[name].unwrap_classes_to_list
      if scope[name].unwrap_contains_class?(ConstNode)
        raise Error::UnsupportedOperation.new(\
          "You cannot modify a const variable. Attepted to modify `#{name}'")
      end
    end
  end

  # access_scope
  #  name     (string)  : Key.
  #  value    (any/nil) : Value to assign to key.
  #  mode     (symbol)  : The mode to operate in.
  #  - `:default`       :  Error if  already defined,
  #                         do not replace.
  #                         Does nothing when `value=nil`.
  #  - `:replace`       :  Replace if already defined.
  #                         Errors when `value=nil`.
  #  - `:retrieve`      :  Return obj if already defined,
  #                         do not replace.
  #                         Errors when `value=nil`.
  #  - `:push`          :  Push to top of scopestack, error if
  #                         already defined in top scopestack.
  #  ignore_const (bool): Allow setting objects even when 
  #                        they're marked as const.
  def access_scope(name,
                   value=nil,
                   mode=:default,
                   ignore_const=false)
    #puts "Access `#{name}` in `#{mode}` mode, with value:"
    #p value
    #puts "\n"
    #if name == "type" && value == nil
    #  raise Error::Magiika.new("fucky wucky") 
    #end
    #puts "\n"

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

    do_skip = @scopes[-1][:@scope_type] == :fn_query
    skip_scope_types = [
      :cls_base,
      :cls_inst,
      :cls_init,
      :cls_ref,
    ]

    @scopes.reverse_each {
      |scope|
      next if scope[name] == nil
      next if do_skip && skip_scope_types.include?(scope[:@scope_type])
      
      if value != nil    # assignment
        case mode
        when :default
          raise Error::AlreadyDefined.new(name)
        when :replace
          verify_not_const(scope, name) if !ignore_const 
          scope[name] = value
          return value
        when :retrieve
          verify_not_const(scope, name) if !ignore_const 
          return scope[name]
        else
          raise Error::Magiika.new("Undefined mode: `#{mode}`")
        end
      else              # retrieval
        return scope[name]
      end
    }

    # name not found
    if value != nil       # assignment
      @scopes[-1][name] = value
      return value
    else                  # retrieval
      raise Error::UndefinedVariable.new(name)
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

  def set(name, obj, mode=:default)
    # This is possible, but not the indended usage of the `set` function.
    raise Error::UnsupportedOperation.new("Attempted to set to nil.") if obj == nil

    return access_scope(name, obj, mode)
  end

  def add(name, obj)
    return access_scope(name, obj, :push)
  end

  def get(name)
    return access_scope(name).unwrap_only_class(ConstNode)
  end

  def get_smart_get(name, obj)
    return access_scope(name, obj, :retrieve).unwrap_only_class(ConstNode)
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
  #  - `:retrieve`    :  Return obj if already defined,
  #                       do not replace.
  #                       Errors when `value=nil`.
  def section_set(name, key, definition=nil, mode=:default)
    section = access_scope(name, Hash.new, :retrieve)
    raise Error::MismatchedType.new(section, Hash) if !section.instance_of?(Hash)

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
