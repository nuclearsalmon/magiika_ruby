#!/usr/bin/env ruby

# ✨ FUNCTIONS
# ------------------------------------------------------------------------------
FUNCTIONS_PROC = Proc.new do
  |scope_handler|
  
  rule :param_list do
    match(:type, ':', :name, ',', :params) {
      |type,_,name,_,params| [[name, type, nil]].concat(params)
    }
    match(:type, ':', :name) {
      |type,_,name| [name, type, nil]
    }

    match(':', :name) {
      |_,name| [name, "magic", nil]
    }
    match(:name) {
      |name| [name, "magic", nil]
    }
  end

  rule :param_def_list do
    match(:type, ':', :name, '=', :expr, ',', :params) {
      |type,_,name,_,value,_,params| [[name, type, value]].concat(params)
    }
    match(:type, ':', :name, '=', :expr) {
      |type,_,name,_,value| [name, type, value]
    }

    match(':', :name, '=', :expr) {
      |_,name,_,value| [name, "magic", value]
    }
    match(:name, '=', :expr) {
      |name,_,value| [name, "magic", value]
    }
  end

  rule :params do
    match(:param_list)
    match(:param_def_list)
  end

  rule :params_block do
    match(:l_parenthesis, :stmts, :r_parenthesis) {
      |_,params,_| params
    }
  end

  rule :func_definition do
    match('fn', ':', :name, :stmts_block) {
      |_,_,name,stmts|
      FunctionDefinition.new(name, nil, "magic", stmts, scope_handler)
    }
    match('fn', ':', :name, '->', :type, :stmts_block) {
      |_,_,name,_,type,stmts|
      FunctionDefinition.new(name, nil, type, stmts, scope_handler)
    }
    match('fn', ':', :name, :parenthesis_block, :stmts_block) {
      |_,_,name,_,stmts|
      FunctionDefinition.new(name, nil, "magic", stmts, scope_handler)
    }
    match('fn', ':', :name, :parenthesis_block, '->', :type, :stmts_block) {
      |_,_,name,_,_,type,stmts|
      FunctionDefinition.new(name, nil, type, stmts, scope_handler)
    }
    match('fn', ':', :name, :params_block, :stmts_block) {
      |_,_,name,_,params,_,stmts|
      FunctionDefinition.new(name, params, "magic", stmts, scope_handler)
    }
    match('fn', ':', :name, :params_block, '->', :type, :stmts_block) {
      |_,_,name,_,params,_,_,type,stmts|
      FunctionDefinition.new(name, params, type, stmts, scope_handler)
    }

    match(':', :name, :stmts_block) {
      |_,name,stmts|
      FunctionDefinition.new(name, nil, "magic", stmts, scope_handler)
    }
    match(':', :name, '->', :type, :stmts_block) {
      |_,name,_,type,stmts|
      FunctionDefinition.new(name, nil, type, stmts, scope_handler)
    }
    match(':', :name, :parenthesis_block, :stmts_block) {
      |_,name,_,stmts|
      FunctionDefinition.new(name, nil, "magic", stmts, scope_handler)
    }
    match(':', :name, :parenthesis_block, '->', :type, :stmts_block) {
      |_,name,_,_,type,stmts|
      FunctionDefinition.new(name, nil, type, stmts, scope_handler)
    }
    match(':', :name, :params_block, :stmts_block) {
      |_,name,params,stmts|
      FunctionDefinition.new(name, params, "magic", stmts, scope_handler)
    }
    match(':', :name, :params_block, '->', :type, :stmts_block) {
      |_,name,params,_,type,stmts|
      FunctionDefinition.new(name, params, type, stmts, scope_handler)
    }
  end

  rule :func_call_args do
    match(:cond, ',', :func_call_args) {
      |arg,_,args| [arg].concat(*args)
    }
    match(:cond) {
      |arg| [arg]
    }
  end

  rule :func_call_args_block do
    match(:l_parenthesis, :func_call_args, :r_parenthesis) {
      |_,args,_| args
    }
  end

  rule :func_call do
    match(:name, :parenthesis_block) {
      |name,_| FunctionCall.new(name, nil, scope_handler)
    }
    match(:name, :func_call_args_block) {
      |name,args| FunctionCall.new(name, args, scope_handler)
    }
  end
end
