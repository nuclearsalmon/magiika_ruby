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
    match(:magic_declare_stmt)
    match(:typed_declare_stmt)
    match(:fn_def)
    match(:eol)
  end

  rule :cls_inherit do
    match('<', :name) {|_,name| name}
  end

  rule :cls_ident do
    match('cls', ':')
    match('class', ':')
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

  rule :cls_member_access do
    match(:name, '.', :name, :fn_call_args_block) do
      |cls,_,member,args|
      ClassFunctionCallStmt.new(cls,member,args)
    end

    match(:name, '.', :name) {
      |cls,_,member|
      ClassAccessStmt.new(cls, member)
    }
  end
end
