#!/usr/bin/env ruby

# ✨ FUNCTIONS
# ------------------------------------------------------------------------------
FUNCTIONS_PROC = Proc.new do
  |scope_handler|

  rule :fn_stmts do
    match(:fn_stmt, :eol, :fn_stmts)  {|stmt,_,stmts| [stmt].concat(stmts)}
    match(:eol, :fn_stmts)            {|_,stmts|      stmts}
    match(:fn_stmt, :eol)             {|stmt,_|       [stmt]}
    match(:fn_stmt)                   {|stmt|         [stmt]}
  end

  rule :fn_stmt do
    match(:return_stmt)
    match(:stmt)
  end

  rule :fn_stmts_block do
    match(:curbracket_block)          {StmtsNode.new([])}
    match(:l_curbracket, :fn_stmts, :r_curbracket) {
      |_,stmts,_| StmtsNode.new(stmts)  # TODO: wrap in temp scope
    }
  end

  rule :param_def_list do
    match(':', :name, '=', :expr, ',', :param_def_list) {
      |_,name,_,value,_,params| [[name, "magic", value]].concat(params)
    }
    match(:type, ':', :name, '=', :expr, ',', :param_def_list) {
      |type,_,name,_,value,_,params| [[name, type, value]].concat(params)
    }

    match(':', :name, '=', :expr) {
      |_,name,_,value| [[name, "magic", value]]
    }
    match(:type, ':', :name, '=', :expr) {
      |type,_,name,_,value| [[name, type, value]]
    }
  end

  rule :param_list do
    match(':', :name, ',', :param_def_list) {
      |_,name,_,params| [[name, "magic", nil]].concat(params)
    }
    match(:type, ':', :name, ',', :param_def_list) {
      |type,_,name,_,params| [[name, type, nil]].concat(params)
    }

    match(':', :name, ',', :param_list) {
      |_,name,_,params| [[name, "magic", nil]].concat(params)
    }
    match(:type, ':', :name, ',', :param_list) {
      |type,_,name,_,params| [[name, type, nil]].concat(params)
    }

    match(:param_def_list)

    match(':', :name) {
      |_,name| [[name, "magic", nil]]
    }
    match(:type, ':', :name) {
      |type,_,name| [[name, type, nil]]
    }
  end

  rule :params_block do
    match(:parenthesis_block) {[]}
    match(:l_parenthesis, :param_list, :r_parenthesis) {
      |_,params,_| params
    }
  end

  rule :fn_ident do
    match(':')
    match('fn', ':')
  end

  rule :fn_ret_ident do
    match('->', :type) {|_,type| type}
  end

  rule :fn_def do
    match(:fn_ident, :name, :fn_stmts_block) {
      |_,name,stmts|
      FunctionDefinition.new(name, [], "magic", stmts, scope_handler)
    }
    match(:fn_ident, :name, :fn_ret_ident, :fn_stmts_block) {
      |_,name,ret_type,stmts|
      FunctionDefinition.new(name, [], ret_type, stmts, scope_handler)
    }

    match(:fn_ident, :name, :params_block, :fn_stmts_block) {
      |_,name,params,stmts|
      FunctionDefinition.new(name, params, "magic", stmts, scope_handler)
    }
    match(:fn_ident, :name, :params_block, :fn_ret_ident, :fn_stmts_block) {
      |_,name,params,ret_type,stmts|
      FunctionDefinition.new(name, params, ret_type, stmts, scope_handler)
    }
  end

  rule :fn_call_args do
    match(:name, '=', :cond, ',', :fn_call_args) {
      |name,_,arg,_,args| [[name, arg]].concat(args)
    }
    match(:cond, ',', :fn_call_args) {
      |arg,_,args| [[nil, arg]].concat(args)
    }
    match(:name, '=', :cond) {
      |name,_,arg| [[name, arg]]
    }
    match(:cond) {
      |arg| [[nil, arg]]
    }
  end

  rule :fn_call_args_block do
    match(:parenthesis_block) {[]}
    match(:l_parenthesis, :fn_call_args, :r_parenthesis) {
      |_,args,_| args
    }
  end

  rule :fn_call do
    match(:name, :fn_call_args_block) {
      |name,args| FunctionCall.new(name, args, scope_handler)
    }
  end
end
