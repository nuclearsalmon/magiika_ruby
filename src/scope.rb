#!/usr/bin/env ruby


class Scope
  attr_reader :scopes

  def initialize
    @scopes = [Hash.new]
  end

  # ⭐ PROTECTED
  # --------------------------------------------------------
  protected

  # access_scope
  #  name           (string): Key.
  #  assignment_obj (any)   : Value to assign to key.
  #  replace        (bool)  : Whether to replace existing value
  #                           (requires assignment_obj).
  #  retrieve       (bool)  : Whether to retrieve value if exists, 
  #                           otherwise assign (requires assignment_obj).
  def access_scope(name, 
                   assignment_obj=nil,
                   replace=false,
                   retrieve=false)
    @scopes.each {
      |scope|
      next if scope[name] == nil    # skip

      if assignment_obj != nil      # assignment
        if replace
          scope[name] = assignment_obj
          return assignment_obj
        end
        if retrieve
          return scope[name]
        end
        raise Error::AlreadyDefined.new(name)
      else                          # retrieval
        return scope[name]
      end
    }

    # handle not found
    if assignment_obj != nil
      @scopes[-1][name] = assignment_obj
      if retrieve
        return assignment_obj
      end
    else
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

  def set(name, obj, replace=false, retrieve=true)
    return access_scope(name, obj, replace=replace, retrieve=retrieve)
  end

  def add(name, obj)
    return access_scope(name, obj, replace=false, retrieve=false)
  end

  def get(name)
    return access_scope(name)
  end

  def get_smart_get(name, obj)
    return access_scope(name, obj, replace=false, retrieve=true)
  end

  # ✨ Scope extension
  # --------------------------------------------------------

  def exec_tmp_scope(type = :temporary, &block)
    begin
      @scopes << {:@scope_type => type}
      block.call
    ensure
      @scopes.delete_at(-1)
    end
  end

  def exec_scope(scope, &block)
    result = nil
    begin
      @scopes << scope
      result = block.call
    ensure
      @scopes.delete_at(-1)
    end
    return result
  end

  def exec_scopes(scopes, &block)
    result = nil
    begin
      scopes.each {|scope| @scopes << scope}
      result = block.call
    ensure
      scopes.each {@scopes.delete_at(-1)}
    end
    return result
  end


  # ✨ Section
  # --------------------------------------------------------

  def section_set(name, key, definition=nil, replace=false, retrieve=false)
    section = access_scope(name, Hash.new, replace=false, retrieve=true)
    raise Error::MismatchedType.new(section, Hash) if !section.instance_of?(Hash)

    if key == nil                 # section instead of section item
      if definition != nil
        raise Error::UnsupportedOperation.new("Section head retrieval with definition.")
      end
      return section
    end

    if definition != nil          # assignment
      if section[key] == nil
        section[key] = definition
        return definition
      elsif replace
        section[key] = definition
        return definition
      elsif retrieve
        return section[key]
      end
      raise Error::AlreadyDefined.new("#{name}[#{key}]")
    else                          # retrieval
      item = section[key]
      raise Error::UndefinedVariable.new("#{name}[#{key}]") if item == nil
      return item
    end
  end

  def section_add(name, key, definition)
    return section_set(name, key, definition, replace=false, retrieve=false)
  end

  def section_get(name, key=nil)
    return section_set(name, key)
  end

  def section_smart_get(name, key, definition)
    return section_set(name, key, definition, replace=false, retrieve=true)
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
