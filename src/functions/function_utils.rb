#!/usr/bin/env ruby


module FunctionUtils
  # ⭐ Keys
  # ---------------------------------------------------------------------------

  def types_from_params(params)
    types = []
    params.each {|param| types << param[:type]}
    return types
  end
  module_function :types_from_params

  def types_from_args(args)
    types = []
    args.each {|arg| types << arg[:value].type}
    return types
  end
  module_function :types_from_args

  def get_fn_key(types)
    item_key = ""
    
    types.each {
      |type|
      item_key += "#{type}, "
    }
    item_key = item_key[0..-3]
    
    return item_key
  end
  module_function :get_fn_key

  def get_fn_sig(name, param_types, ret_type)
    params = ""
    param_types.each {
      |param_type|
      params += "#{param_type}, "
    }
    params = params[0..-3]

    return "#{name}(#{params}) -> #{ret_type}"
  end
  module_function :get_fn_sig

  def get_full_fn_sig(name, params, ret_type)
    item_key = "#{name}(" 
    
    params.each {
      |param_name, param_type|
      item_key += "#{param_type}: #{param_name}, "
    }
    item_key = item_key[0..-3]
    
    item_key += ") -> #{ret_type}"
    
    return item_key
  end
  module_function :get_full_fn_sig


  # ⭐ Function definition argument fitting
  # ---------------------------------------------------------------------------

  def fill_params(fn_def, args)
    params = fn_def[:params]

    raise Error::BadNrOfArgs.new(fn_def, -1) if params.length < args.length
    
    # map params
    params_map = Hash[params.collect{|v| [v[:name], v]}]
    param_values = Hash.new

    # parse args
    args.each_with_index {
      |arg, idx|
      arg_name, arg_value = arg[:name], arg[:value]
      
      # derive arg name from param order if undefined
      if arg_name == nil
        arg_name = params[idx][:name]
        raise Error::BadNrOfArgs.new(fn_def, -1) if arg_name == nil
      end
      
      # get param by arg name
      param = params_map[arg_name]
      raise Error::BadArgName.new(fn_def, arg_name) if param == nil
      param_type, _, param_def_val = *param

      # check param not already assigned
      if param_values[arg_name] != nil
        raise Error::AlreadyDefined.new("Argument #{arg_name}")
      end

      # check param type matches arg type
      if !(param[:type] == "magic" || param[:type] == arg_value.type)
        raise Error::MismatchedType.new(arg_value, param_type)
      end

      # assign arg value to param
      param_values[arg_name] = arg_value
    }

    # assign default if misisng ,otherwise error
    params.each {
      |param|
      param_name, param_def_val = param[:name], param[:value]

      next if param_values[param_name] != nil

      if param_def_val == nil
        full_fn_sig = get_full_fn_sig(fn_def[:name], fn_def[:params], fn_def[:ret_type])
        raise Error::BadNrOfArgs.new(full_fn_sig, -1) 
      end

      param_values[param_name] = param_def_val
    }

    return param_values
  end
  module_function :fill_params

  def find_fn(name, args, scope)
    fn_section = scope.section_get(name)
    fn_section.each {
      |_,fn_def|

      begin
        param_values = fill_params(fn_def, args)
        return [fn_def, param_values]
      rescue Error::BadNrOfArgs, Error::BadArgName, \
          Error::MismatchedType, Error::AlreadyDefined
        nil
      end
    }

    puts "\n"
    p scope.scopes[-1]
    sig = "#{name}(#{get_fn_key(types_from_args(args))})"
    raise Error::UndefinedVariable.new(sig)
  end
  module_function :find_fn
end
