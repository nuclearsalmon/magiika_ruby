#!/usr/bin/env ruby

# ✨ FUNCTIONS
# ------------------------------------------------------------------------------
FUNCTIONS_PROC = Proc.new do
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
      |_,stmts,_| StmtsNode.new(stmts)  # TODO: wrap in temporary scope
    }
  end

  rule :param_def_list do
    match(:type_ident, :name, '=', :expr, ',', :param_def_list) {
      |type,name,_,value,_,params|
      [{:name => name, :type => type, :value => value}].concat(params)
    }

    match(:type_ident, :name, '=', :expr) {
      |type,name,_,value|
      [{:name => name, :type => type, :value => value}]
    }
  end

  rule :param_list do
    match(:type_ident, :name, ',', :param_def_list) {
      |type,name,_,params|
      [{:name => name, :type => type, :value => nil}].concat(params)
    }

    match(:type_ident, :name) {
      |type,name| [{:name => name, :type => type, :value => nil}]
    }

    match(:type_ident, :name, ',', :param_list) {
      |type,name,_,params|
      [{:name => name, :type => type, :value => nil}].concat(params)
    }

    match(:param_def_list)
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
    match(:fn_ident, :name, :params_block, :fn_stmts_block) {
      |_,name,params,stmts|
      FunctionDefStmt.new(name, params, "magic", stmts)
    }
    match(:fn_ident, :name, :params_block, :fn_ret_ident, :fn_stmts_block) {
      |_,name,params,ret_type,stmts|
      FunctionDefStmt.new(name, params, ret_type, stmts)
    }
  end

  rule :fn_call_args do
    match(:name, '=', :cond, ',', :fn_call_args) {
      |name,_,value,_,args| [{:name => name, :value => value}].concat(args)
    }
    match(:cond, ',', :fn_call_args) {
      |value,_,args| [{:name => nil, :value => value}].concat(args)
    }
    match(:name, '=', :cond) {
      |name,_,value| [{:name => name, :value => value}]
    }
    match(:cond) {
      |value| [{:name => nil, :value => value}]
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
      |name,args| FunctionCallStmt.new(name, args)
    }
  end
end
