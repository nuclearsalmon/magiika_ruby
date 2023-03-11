#!/usr/bin/env ruby

require_relative './functions.rb'  # FunctionUtils


class ScopeHandler
  attr_reader :scopes

  def initialize
    @scopes = [Hash.new]
  end

  def access_scope(name, assignment_obj = nil, param_key = nil)
    i = @scopes.length-1  # set to end of scope stack
    only_class_or_global = false

    while (i >= 0)
      target = @scopes[i][name]
      if target == nil
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
  
  def temp_fn_call_scope(name, args)
    fn_def = get_func(name, FunctionUtils.get_fn_key(args))
    params, ret_type, stmts = *fn_def
    fn_sig = FunctionUtils.get_fn_sig(name, params, ret_type)

    params_map = Hash[params.collect{|v| [v[0], v[1..-1]]}]
    param_values = Hash.new
    args.each_with_index {
      |arg, idx|
      arg_name, arg_val = *arg
      
      # find arg name
      if arg_name == nil
        raise MagiikaBadNrOfArgsError.new(fnsig, -1) if params.length < idx
        arg_name = params[idx][0]
        raise MagiikaBadNrOfArgsError.new(fnsig, -1) if arg_name == nil
      end
      
      # get param
      param = params_map[arg_name]
      raise MagiikaBadArgNameError.new(fn_sig, arg_name) if param == nil
      param_type, param_name, param_def_val = *param

      # check param not already assigned
      if param_values[arg_name] != nil
        raise MagiikaAlreadyDefinedError.new("Argument #{arg_name}")
      end

      # check param type matches arg type
      if param_type != "magic" && param_type != arg_val.type
        raise MagiikaMismatchedTypeError.new(arg_val, param_type)
      end

      # assign arg value to param
      param_values[arg_name] = arg_val
    }

    # assign defaults
    params.each {
      |param|
      param_name, param_type, param_def_val = *param

      next if param_values[param_name] != nil
      raise MagiikaBadNrOfArgsError.new(fn_sig, -1) if param_def_val == nil
      param_values[param_name] = param_def_val
    }

    # run in temporary scope
    result = nil
    temp_scope {
      param_values.each {
        |param_name, param_val|
        add_var(param_name, param_val)
      }
      result = stmts.eval
    }

    # typecheck return value and ensure it's a node
    result = EmptyNode.get_default if result == nil
    if !(ret_type == "magic" && result.type == "empty") && 
      ret_type != result.type
      raise MagiikaMismatchedTypeError(result, ret_type)
    end
    return result
  end
end
