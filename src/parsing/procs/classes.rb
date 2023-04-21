#!/usr/bin/env ruby


# ✨ CLASSES
# ------------------------------------------------------------------------------
CLASSES_PROC = Proc.new do
  # ⭐ ATTRIBUTES & ACCESSORS
  # ----------------------------------------------------------------------------

  rule :accessor do
    match("public")                     {:public}
    match("publ")                       {:public}
    match("pub")                        {:public}
    match("private")                    {:private}
    match("priv")                       {:private}
    match("protected")                  {:protected}
    match("prot")                       {:protected}
  end

  rule :static do
    match("static")                     {:static}
    match("stat")                       {:static}
  end

  rule :abstract do
    match("abstract")                   {:abstract}
    match("abst")                       {:abstract}
  end


  # ✨ CLASSES 
  # ----------------------------------------------------------------------------

  rule :cls_stmts do
    match(:cls_stmt, :eol, :cls_stmts)  {|stmt,_,stmts| [stmt].concat(stmts)}
    match(:eol, :cls_stmts)             {|_,stmts|      stmts}
    match(:cls_stmt, :eol)              {|stmt,_|       [stmt]}
    match(:cls_stmt)                    {|stmt|         [stmt]}
  end

  rule :cls_stmts_block do
    match(:curbracket_block)            {[]}
    match(:l_curbracket, :cls_stmts, :r_curbracket) {
      |_,stmts,_| stmts  # TODO: wrap in tmp scope (?)
    }
  end

  rule :cls_stmt do
    match(:cls_def)

    match(:static, :fn_def)       {|_,fn_def| StaticNode.new(fn_def)}
    match(:fn_def)

    match(:static, :declare_var)  {|_,stmt| StaticNode.new(stmt)}
    match(:declare_var)

    match(:eol)
  end

  rule :cls_inherit do
    match('<', :name) {|_,name| name}
  end

  rule :cls_ident do
    match('class', ':')
    match('cls', ':')
    match(':')
  end

  rule :cls_def do
    match(:cls_ident, :name, :cls_inherit, :cls_stmts_block) {
      |_,name,cls_inh,stmts|
      ClassDefStmt.new(name, stmts, cls_inh)
    }
    match(:cls_ident, :name, :cls_stmts_block) {
      |_,name,stmts|
      ClassDefStmt.new(name, stmts, nil)
    }
  end

  rule :abs_cls_def do
    match(:abstract, :cls_ident, ':', :name, :cls_inherit, :cls_stmts_block) {
      |_,_,_,name,cls_inh,stmts|
      AbstractClassDefStmt.new(name, stmts, cls_inh)
    }
  end
end
