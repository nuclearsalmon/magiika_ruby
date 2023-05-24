#!/usr/bin/env ruby

# ✨ FUNCTIONS
# ------------------------------------------------------------------------------
FUNCTIONS_PROC = Proc.new do
  # ✨ Statements
  # --------------------------------------------------------

  rule :fn_stmts do
    match(:fn_stmt, :eol, :fn_stmts)    {|stmt,_,stmts| [stmt].concat(stmts)}
    match(:eol, :fn_stmts)              {|_,stmts|      stmts}
    match(:fn_stmt, :eol)               {|stmt,_|       [stmt]}
    match(:fn_stmt)                     {|stmt|         [stmt]}
    match(:eol)                         {[]}
    match('')                           {[]}
  end

  rule :fn_stmt do
    match(:nested_stmt)
  end

  rule :fn_stmts_block do
    match(:curbracket_block)            {StmtsNode.new([])}
    match(:l_curbracket, :fn_stmts, :r_curbracket) {
      |_,stmts,_| StmtsNode.new(stmts)
    }
  end


  # ✨ Parameters
  # --------------------------------------------------------

  rule :param_def_list do
    match(:type_ident, :name, '=', :expr, ',', :param_def_list) {
      |ident,name,_,value,_,params|
      attribs, type = *ident
      [{:attribs => attribs, :type => type, :name => name, :value => value}].concat(params)
    }

    match(:type_ident, :name, '=', :expr) {
      |ident,name,_,value|
      attribs, type = *ident
      [{:attribs => attribs, :type => type, :name => name, :value => value}]
    }
  end

  rule :param_list do
    match(:type_ident, :name, ',', :param_def_list) {
      |ident,name,_,params|
      attribs, type = *ident
      [{:attribs => attribs, :type => type, :name => name, :value => nil}].concat(params)
    }

    match(:type_ident, :name, ',', :param_list) {
      |ident,name,_,params|
      attribs, type = *ident
      [{:attribs => attribs, :type => type, :name => name, :value => nil}].concat(params)
    }
    
    match(:param_def_list)

    match(:type_ident, :name) {
      |ident,name|
      attribs, type = *ident
      [{:attribs => attribs, :type => type, :name => name, :value => nil}]
    }
  end

  rule :params_block do
    match(:parenthesis_block) {[]}
    match(:l_parenthesis, :param_list, :r_parenthesis) {
      |_,params,_| params
    }
  end


  # ✨ Identification
  # --------------------------------------------------------

  rule :fn_ident_type do
    match('fn', ':')
    match(':')
  end

  rule :fn_ident do
    match(:abstract, :fn_ident_type)    {|abst,_| [abst]}
    match(:fn_ident_type)               {[]}
  end

  # ✨ Return value
  # --------------------------------------------------------

  rule :fn_ret_ident do
    match('->', :attributed_type) {|_,ident| ident}
  end


  # ✨ Definition
  # --------------------------------------------------------

  rule :fn_def do
    match(:fn_ident, :name, :params_block, :fn_stmts_block) {
      |attribs,name,params,stmts|
      FunctionDefStmt.new(attribs, name, params, [], nil, stmts)
    }
    match(:fn_ident, :name, :params_block, :fn_ret_ident, :fn_stmts_block) {
      |attribs,name,params,ret_ident,stmts|
      ret_attribs, ret_type = *ret_ident
      FunctionDefStmt.new(attribs, name, params, ret_attribs, ret_type, stmts)
    }
  end


  # ✨ Call arguments
  # --------------------------------------------------------

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


  # ✨ Call
  # --------------------------------------------------------

  rule :fn_call do
    match(:name, :fn_call_args_block) {
      |name,args| FunctionCallStmt.new(name, args)
    }
  end
end
