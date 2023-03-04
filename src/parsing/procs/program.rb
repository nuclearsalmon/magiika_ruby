#!/usr/bin/env ruby

# ✨ PROGRAM / CONTROL FLOW
# ------------------------------------------------------------------------------
PROGRAM_PROC = Proc.new do
  |scope_handler|

  start :program do
    match(:stmts)               {|stmts| stmts.eval}
  end

  rule :stmts do
    # handle various EOL combinations
    match(:stmt, :eol, :stmts)  {|stmt,_,stmts| StmtsNode.new(stmt, stmts)}
    match(:eol, :stmts)         {|stmt,stmts|   StmtsNode.new(stmt, stmts)}
    match(:stmt, :eol)          {|stmt,_|       StmtsNode.new(stmt, nil)}
    match(:eol)                 {|stmt|         StmtsNode.new(stmt, nil)}

    # handle files that don't end in an EOL
    match(:stmt)                {|stmt|         StmtsNode.new(stmt, nil)}
  end

  rule :stmt do
    match(:syslib_call)

    match(:if_stmt)
    match(:while_stmt)

    match(:func_definition)
    match(:func_call)

    match(:declare_stmt)
    match(:assign_stmt)

    match(:cond)
  end

  rule :syslib_call do
    match('$', :cond) {|_,obj| PrintNode.new(obj)}
  end
  
  rule :elif_keyword do
    match(:eol, "elif")
    match("elif")
  end
  
  rule :else_keyword do
    match(:eol, "else")
    match("else")
  end

  rule :stmts_block do
    match(:l_curbracket, :stmts, :r_curbracket) {
      |_,stmts,_| stmts
    }
  end

  rule :if_stmt do
    match("if", :cond, ":", :stmt, :elif_stmt) {
      |_,cond,_,stmt,elif|
      IfNode.new(cond, stmt, scope_handler, else_stmt=elif)
    }
    match("if", :cond, ":", :stmt) {
      |_,cond,_,stmt|
      IfNode.new(cond, stmt, scope_handler)
    }

    match("if", :cond, :stmts_block, :elif_stmt) {
      |_,cond,stmts,elif|
      IfNode.new(cond, stmts, scope_handler, else_stmt=elif)
    }
    match("if", :cond, :stmts_block) {
      |_,cond,stmts|
      IfNode.new(cond, stmts, scope_handler)
    }
  end

  rule :elif_stmt do
    match(:elif_keyword, :cond, ":", :stmt, :elif_stmt) {
      |_,cond,_,stmt,elif|
      IfNode.new(cond, stmt, scope_handler, elif_else=elif)
    }
    match(:elif_keyword, :cond, ":", :stmt) {
      |_,cond,_,stmt|
      IfNode.new(cond, stmt, scope_handler)
    }

    match(:elif_keyword, :cond, :stmts_block, :elif_stmt) {
      |_,cond,stmts,elif|
      IfNode.new(cond, stmts, scope_handler, elif_else=elif)
    }
    match(:elif_keyword, :cond, :stmts_block) {
      |_,cond,stmts|
      IfNode.new(cond, stmts, scope_handler)
    }

    match(:else_stmt)
  end

  rule :else_stmt do
    match(:else_keyword, ":", :stmt) {
      |_,_,stmt|
      cond = BoolNode.new(true)  # always eval to true
      IfNode.new(cond, stmt, scope_handler)
    }

    match(:else_keyword, :stmts_block) {
      |_,stmts|
      cond = BoolNode.new(true)  # always eval to true
      IfNode.new(cond, stmts, scope_handler)
    }
  end

  rule :while_stmt do
    match("while", :cond, ":", :stmt) {
      |_,cond,_,stmt|
      WhileNode.new(cond, stmt, scope_handler)
    }

    match("while", :cond, :stmts_block) {
      |_,cond,stmts|
      WhileNode.new(cond, stmts, scope_handler)
    }
  end
end
