#!/usr/bin/env ruby


module FunctionUtils
  # ⭐ Keys
  # ---------------------------------------------------------------------------

  def types_from_params(params)
    types = []
    params.each {
      |param|
      types << param[:type] == nil ? 'magic' : param[:type]
    }
    return types
  end
  module_function :types_from_params

  def types_from_args(args)
    types = []
    args.each {
      |arg|
      type = arg[:value].respond_to?(:type) ? arg[:value].type : nil
      types << type
    }
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

  def fill_params(fn_def, args, scope)
    params = fn_def.params

    raise Error::BadNrOfArgs.new(fn_def, -1) if params.length < args.length
    
    # map params
    params_map = Hash[params.collect{|v| [v[:name], v]}]
    fn_call_scope = Hash.new

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

      # check param not already assigned
      if fn_call_scope[arg_name] != nil
        raise Error::AlreadyDefined.new("Argument #{arg_name}")
      end

      arg_value = arg_value.eval(scope)

      # assign arg value to param
      arg_value = arg_value.unwrap_only_class(MetaNode)
      begin
        arg_meta = MetaNode.new(param[:attribs], arg_value, param[:type])
        fn_call_scope[arg_name] = arg_meta
      rescue
        metaspec = MetaNode.new(param[:attribs], nil, param[:type], true)
        raise Error::MismatchedType.new(arg_value, metaspec)
      end
    }

    # assign default if missing, otherwise error
    params.each {
      |param|

      next if fn_call_scope[param[:name]] != nil

      if param[:value] == nil
        full_fn_sig = get_full_fn_sig(fn_def[:name], fn_def[:params], fn_def[:ret_type])
        raise Error::BadNrOfArgs.new(full_fn_sig, -1) 
      end

      param_def_meta = MetaNode.new(param[:attribs], param[:value], param[:type])
      fn_call_scope[param[:name]] = param_def_meta
    }

    # eval all values
    fn_call_scope.each {|name,value| fn_call_scope[name] = value.eval(scope)}

    # set scope type
    fn_call_scope[:@scope_type] = :fn_call

    return fn_call_scope
  end
  module_function :fill_params

  def find_fn(name, args, scope)
    fn_section = scope.section_get(name)
    fn_section.each {
      |_,fn_def_meta|

      begin
        fn_call_scope = fill_params(fn_def_meta.unwrap, args, scope)
        return [fn_def_meta, fn_call_scope]
      rescue Error::BadNrOfArgs, Error::BadArgName, \
          Error::MismatchedType, Error::AlreadyDefined
        nil
      end
    }

    sig = "#{name}(#{get_fn_key(types_from_args(args))})"
    raise Error::UndefinedVariable.new(sig)
  end
  module_function :find_fn
end
