#!/usr/bin/env ruby

# ✨ PROGRAM / CONTROL FLOW
# ------------------------------------------------------------------------------
PROGRAM_PROC = Proc.new do
  start :program do
    match(:stmts)               {|stmts| StmtsNode.new(stmts)}
  end

  rule :eol do
    match(:eol, :eol)
    match(:eol_tok)
    match(:eol_mark)
  end

  rule :stmts do
    match(:stmt, :eol, :stmts)  {|stmt,_,stmts| [stmt].concat(stmts)}
    match(:eol, :stmts)         {|_,stmts|      stmts}
    match(:stmt, :eol)          {|stmt,_|       [stmt]}
    match(:stmt)                {|stmt|         [stmt]}
  end

  rule :stmt do
    match(:syslib_call)

    match(:if_stmt)
    match(:while_stmt)
    match(:return_stmt)

    match(:cls_def)

    match(:fn_def)

    match(:member_assign)
    match(:reassign_var)
    match(:const, :declare_var) {|_,stmt| ConstStmt.new(stmt)}
    match(:declare_var)

    match(:cond)
  end
  
  rule :oneline_stmt do
    match(:eol, :stmt)          {|_,stmt| stmt}
    match(:stmt)
  end
  
  rule :stmts_block do
    match(:l_curbracket, :stmts, :r_curbracket) {
      |_,stmts,_| StmtsNode.new(stmts)  # TODO: wrap in temporary scope
    }
  end

  rule :return_stmt do
    match('return', :cond)      {|_,stmt| ReturnStmtNode.new(stmt)}
    match('return')             {ReturnStmtNode.new(nil)}
  end
  
  rule :break_stmt do
    match('break')              {BreakStmtNode.new}
  end

  rule :continue_stmt do
    match('continue')           {ContinueStmtNode.new}
  end

  rule :syslib_call do
    match('$', :cond) {|_,obj| PrintNode.new(obj)}
  end
  
  rule :elif_keyword do
    match(:eol, 'elif')
    match('elif')
  end
  
  rule :else_keyword do
    match(:eol, 'else')
    match('else')
  end

  rule :if_stmt do
    match('if', :cond, ':', :oneline_stmt, :elif_stmt) {
      |_,cond,_,stmt,elif|
      IfNode.new(cond, stmt, else_stmt=elif)
    }
    match('if', :cond, ':', :oneline_stmt) {
      |_,cond,_,stmt|
      IfNode.new(cond, stmt)
    }

    match('if', :cond, :stmts_block, :elif_stmt) {
      |_,cond,stmts,elif|
      IfNode.new(cond, stmts, else_stmt=elif)
    }
    match('if', :cond, :stmts_block) {
      |_,cond,stmts|
      IfNode.new(cond, stmts)
    }
  end

  rule :elif_stmt do
    match(:elif_keyword, :cond, ':', :oneline_stmt, :elif_stmt) {
      |_,cond,_,stmt,elif|
      IfNode.new(cond, stmt, elif_else=elif)
    }
    match(:elif_keyword, :cond, ':', :oneline_stmt) {
      |_,cond,_,stmt|
      IfNode.new(cond, stmt)
    }

    match(:elif_keyword, :cond, :stmts_block, :elif_stmt) {
      |_,cond,stmts,elif|
      IfNode.new(cond, stmts, elif_else=elif)
    }
    match(:elif_keyword, :cond, :stmts_block) {
      |_,cond,stmts|
      IfNode.new(cond, stmts)
    }

    match(:else_stmt)
  end

  rule :else_stmt do
    match(:else_keyword, ':', :oneline_stmt) {
      |_,_,stmt|
      cond = BoolNode.new(true)  # always eval to true
      IfNode.new(cond, stmt)
    }

    match(:else_keyword, :stmts_block) {
      |_,stmts|
      cond = BoolNode.new(true)  # always eval to true
      IfNode.new(cond, stmts)
    }
  end

  rule :while_stmt do
    match('while', :cond, ':', :oneline_stmt) {
      |_,cond,_,stmt|
      WhileNode.new(cond, stmt)
    }

    match('while', :cond, :stmts_block) {
      |_,cond,stmts|
      WhileNode.new(cond, stmts)
    }
  end
end
