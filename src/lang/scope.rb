#!/usr/bin/env ruby


class Scope
  attr_reader :scopes

  def initialize
    @scopes = [{:@scope_type => :global}]
  end

  SEPARATOR_SCOPE_SLICE = {:@scope_type => :"---"   }.freeze
  FN_QUERY_SCOPE_SLICE  = {:@scope_type => :fn_query}.freeze

  # ⭐ PROTECTED
  # --------------------------------------------------------
  protected

  def verify_not_const(scope, name) 
    if scope[name].class <= TypeNode
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
    incl_scope_filter = [
      :cls_base,
      :cls_inst,
      :cls_init,
      :cls_ref,
      :cls_run,
      :fn_call,
    ]
    while i >= 0
      scope = @scopes[i]
      
      #puts "---"
      #p name
      #p mode
      #p filter_scopes
      #p scope[:@scope_type]
      #p scope[name]
      #p scope
      #puts "---"

      if (filter_scopes && scope[:@scope_type] != :global \
          && !incl_scope_filter.include?(scope[:@scope_type]))
        nil # do nothing
      elsif scope[name] != nil
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
    result = access_scope(name)
    if result.class <= TypeNode
      result = result.unwrap_only_class(ConstNode)
    end
    return result
  end

  def get_smart_get(name, obj)
    result = access_scope(name, obj, :retrieve)
    if result.class <= TypeNode
      result = result.unwrap_only_class(ConstNode)
    end
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
  #  - `:retrieve`    :  Return obj if already defined,
  #                       do not replace.
  #                       Errors when `value=nil`.
  def section_set(name, key, definition=nil, mode=:default)
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
      return
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
