#!/usr/bin/env ruby


class ScopeHandler
  def initialize
    @scopes = [Hash.new]
  end

  def access_scope(name, assignment_obj = nil, param_key = nil)
    i = @scopes.length-1  # set to end of scope stack
    only_class_or_global = false

    while (i >= 0)
      target = @scopes[i][name]
      if target == nil then
        i -= 1
        next  # skip
      end

      if param_key == nil             # name-based
        if assignment_obj != nil      # assignment
          @scopes[i][name] = assignment_obj
          return  # FIXME: return `assignment_obj' here?
        else                          # retrieval
          return target
        end
      else                            # param_key-based
        next if target.class != Hash  # skip non-hashes
        
        if assignment_obj != nil      # assignment
          target[param_key] = assignment_obj
          return  # FIXME: return `assignment_obj' here?
        else                          # retrieval
          return target[param_key]
        end
      end
    end

    raise MagiikaUndefinedVariableError.new(name)
  end

  def add_var(name, obj)
    if @scopes[-1][name] == nil
      @scopes[-1][name] = obj
    else
      raise MagiikaAlreadyDefinedError.new(name)
    end
  end

  def relaxed_add_var(name, obj)
    if @scopes[-1][name] == nil
      @scopes[-1][name] = obj
    else
      set_var(name, obj)
    end
  end

  def get_var(name)
    return access_scope(name)
  end

  def set_var(name, obj)
    return access_scope(name, obj)
  end

  def new_scope
    @scopes << Hash.new
  end

  def discard_scope
    @scopes.delete_at(-1)
  end

  def temp_scope(&block)
    begin
      new_scope
      block.call
    ensure
      discard_scope
    end
  end

  def add_func(name, param_key, definition)
    # register new name
    if @scopes[-1][name] == nil
      @scopes[-1][name] = Hash.new
    else
      raise MagiikaAlreadyDefinedError.new(name)
    end

    # register new param_key for this name
    if @scopes[-1][name][param_key] == nil
      @scopes[-1][name][param_key] = definition
    else
      raise MagiikaAlreadyDefinedError.new("#{name}(#{param_key})")
    end
  end

  def get_func(name, param_key)
    return access_scope(name, nil, param_key)
  end
end
