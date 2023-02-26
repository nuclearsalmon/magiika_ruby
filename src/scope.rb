#!/usr/bin/env ruby


class ScopeHandler
  def initialize
    @scopes = [Hash.new]
  end

  def access_scope(name, assignment_obj = nil)
    i = @scopes.length-1  # set to end of scope stack
    only_class_or_global = false

    while (i >= 0)
      if @scopes[i][name] != nil && @scopes[i][name].class != Hash
        # Assignment
        if assignment_obj != nil
          @scopes[i][name] = assignment_obj
          return  # FIXME: return `assignment_obj' here?
        # Retrieval
        else
          return @scopes[i][name]
        end
      end

      i -= 1
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
end
