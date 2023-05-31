#!/usr/bin/env ruby


# ✨ CLASSES
# -----------------------------------------------------------------------------
CLASSES_PROC = Proc.new do
  # ✨ Statements
  # --------------------------------------------------------

  rule :cls_stmts do
    match(:cls_stmt, :eol, :cls_stmts)  {|stmt,_,stmts| [stmt].concat(stmts)}
    match(:eol, :cls_stmts)             {|_,stmts|      stmts}
    match(:cls_stmt, :eol)              {|stmt,_|       [stmt]}
    match(:cls_stmt)                    {|stmt|         [stmt]}
    match(:eol)                         {[]}
    match('')                           {[]}
  end

  rule :cls_stmt do
    match(:cls_cls_def)
    match(:cls_fn_def)
    match(:cls_declare_var)
  end

  rule :cls_stmts_block do
    match(:curbracket_block)            {[]}
    match(:l_curbracket, :cls_stmts, :r_curbracket) {|_,stmts,_| stmts}
  end


  # ✨ Identification
  # --------------------------------------------------------

  rule :cls_ident_type do
    match('cls', ':')
    match(':')
  end

  rule :cls_ident do
    match(:abstract, :cls_ident_type)   {|abst| [abst]}
    match(:cls_ident_type)              {[]}
  end


  # ✨ Inheritance
  # --------------------------------------------------------

  rule :inherit do
    match('<', :type)                   {|_,type| type}
  end

  # ✨ Definition
  # --------------------------------------------------------

  rule :cls_def do
    match(:cls_ident, :name, :inherit, :cls_stmts_block) {
      |attribs,name,cls_inh,stmts|
      ClassDefStmt.new(attribs, name, stmts, cls_inh)
    }
    match(:cls_ident, :name, :cls_stmts_block) {
      |attribs,name,stmts|
      ClassDefStmt.new(attribs, name, stmts, nil)
    }
  end


  # ✨ Nested function declaration
  # ---------------------------------------------------------------------------
  
  rule :cls_fn_attrib do
    match(:accessor)
    match(:static)
    match(:abstract)
  end

  rule :cls_fn_attribs do
    match(:cls_fn_attrib, :cls_fn_attribs)  {|attrib, attribs| [attrib].concat(attribs)}
    match(:cls_fn_attrib)                   {|attrib| [attrib]}
  end

  rule :cls_fn_ident do
    match(:cls_fn_attribs, :fn_ident_type)  {|attribs,_| attribs}
    match(:fn_ident_type)                   {[]}
  end

  rule :cls_fn_def do
    match(:cls_fn_ident, :name, :params_block, :fn_stmts_block) {
      |attribs,name,params,stmts|
      FunctionDefStmt.new(attribs, name, params, [], nil, stmts)
    }
    match(:cls_fn_ident, :name, :params_block, :fn_ret_ident, :fn_stmts_block) {
      |attribs,name,params,ret_ident,stmts|
      ret_attribs, ret_type = *ret_ident
      FunctionDefStmt.new(attribs, name, params, ret_attribs, ret_type, stmts)
    }

    match(:cls_fn_attribs, :fn_ident_type, :name, :params_block) {
      |attribs,_,name,params|
      if !(attribs.include?(:abst))
        raise Error::UnsupportedOperation.new('Functions without {} must be marked as abstract.')
      end

      FunctionDefStmt.new(attribs, name, params, [], nil, [])
    }
    match(:cls_fn_attribs, :fn_ident_type, :name, :params_block, :fn_ret_ident) {
      |attribs,_,name,params,ret_ident|
      if !(attribs.include?(:abst))
        raise Error::UnsupportedOperation.new('Functions without {} must be marked as abstract.')
      end

      ret_attribs, ret_type = *ret_ident
      FunctionDefStmt.new(attribs, name, params, ret_attribs, ret_type, [])
    }
  end


  # ✨ Nested types and attributed types
  # ---------------------------------------------------------------------------

  rule :cls_type_attrib do
    match(:accessor)
    match(:static)
    match(:type_attrib)
  end

  rule :cls_type_attribs do
    match(:cls_type_attrib, :cls_type_attribs)  {|attrib, attribs| [attrib].concat(attribs)}
    match(:cls_type_attrib)                     {|attrib|          [attrib]}
  end

  rule :cls_attributed_type do
    match(:cls_type_attribs, :type) {|attribs,type| [attribs, type]}
    match(:cls_type_attribs)        {|attribs|      [attribs, nil]}
    match(:type)                    {|type|         [[], type]}
  end

  rule :cls_type_ident do
    match(:cls_attributed_type, ':')  {|ident,_| ident}
    match(':')                        {[[], nil]}
  end


  # ✨ Nested variable declaration
  # -------------------------------------------------------

  rule :cls_declare_var do
    match(:cls_type_ident, :name, '=', :expr) {
      |ident,name,_,value| 
      attribs, type = *ident
      DeclareVariableStmt.new(attribs, type, name, value)
    }
    match(:cls_type_ident, :name) {
      |ident,name|
      attribs, type = *ident
      DeclareVariableStmt.new(attribs, type, name)
    }
  end


  # ✨ Nested class definition
  # --------------------------------------------------------

  rule :cls_cls_attrib do
    match(:accessor)
    match(:abstract)
  end

  rule :cls_cls_attribs do
    match(:cls_cls_attrib, :cls_cls_attribs)  {|attrib, attribs| [attrib].concat(attribs)}
    match(:cls_cls_attrib)                    {|attrib| [attrib]}
  end

  rule :cls_cls_ident do
    match(:cls_cls_attribs, :cls_ident_type)  {|attribs,_| attribs}
    match(:cls_ident_type)                    {[]}
  end

  rule :cls_cls_def do
    match(:cls_cls_ident, :name, :inherit, :cls_stmts_block) {
      |attribs,name,cls_inh,stmts|
      ClassDefStmt.new(attribs, name, stmts, cls_inh)
    }
    match(:cls_cls_ident, :name, :cls_stmts_block) {
      |attribs,name,stmts|
      ClassDefStmt.new(attribs, name, stmts, nil)
    }
  end
end
