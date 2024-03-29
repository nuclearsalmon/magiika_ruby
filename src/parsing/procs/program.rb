#!/usr/bin/env ruby

# ✨ PROGRAM / CONTROL FLOW
# ------------------------------------------------------------------------------
PROGRAM_PROC = Proc.new do
  start :program do
    match(:stmts)               {|stmts| StmtsNode.new(stmts)}
    match('')                   {StmtsNode.new([])}
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
    match(:eol)                 {[]}
    match('')                   {[]}
  end

  rule :stmt do
    match(:syslib_call)

    match(:if_stmt)
    match(:while_stmt)

    match(:fn_def)
    match(:cls_def)
    
    match(:member_assign)
    
    match(:reassign_var)
    match(:declare_var)

    match(:cond)
  end
  
  rule :oneline_stmt do
    match(:eol, :stmt)          {|_,stmt| stmt}
    match(:eol, :stmt, :eol)    {|_,stmt,_| stmt}
    match(:stmt)
  end
  
  rule :stmts_block do
    match(:curbracket_block)    {StmtsNode.new([])}
    match(:l_curbracket, :stmts, :r_curbracket) {|_,stmts,_| StmtsNode.new(stmts)}
  end

  rule :nested_stmts do
    match(:nested_stmt, :eol, :nested_stmts)  {|stmt,_,stmts| [stmt].concat(stmts)}
    match(:eol, :nested_stmts)                {|_,stmts|      stmts}
    match(:nested_stmt, :eol)                 {|stmt,_|       [stmt]}
    match(:nested_stmt)                       {|stmt|         [stmt]}
    match(:eol)                               {[]}
    match('')                                 {[]}
  end

  rule :nested_stmt do
    match(:return_stmt)
    match(:stmt)
  end

  rule :nested_oneline_stmt do
    match(:eol, :nested_stmt)          {|_,stmt| stmt}
    match(:eol, :nested_stmt, :eol)    {|_,stmt,_| stmt}
    match(:nested_stmt)
  end

  rule :nested_stmts_block do
    match(:curbracket_block)    {StmtsNode.new([])}
    match(:l_curbracket, :nested_stmts, :r_curbracket) {
      |_,stmts,_| StmtsNode.new(stmts)
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
    match('if', :cond, ':', :nested_oneline_stmt, :elif_stmt) {
      |_,cond,_,stmt,elif|
      IfNode.new(cond, stmt, else_stmt=elif)
    }
    match('if', :cond, ':', :nested_oneline_stmt) {
      |_,cond,_,stmt|
      IfNode.new(cond, stmt)
    }

    match('if', :cond, :nested_stmts_block, :elif_stmt) {
      |_,cond,stmts,elif|
      IfNode.new(cond, stmts, else_stmt=elif)
    }
    match('if', :cond, :nested_stmts_block) {
      |_,cond,stmts|
      IfNode.new(cond, stmts)
    }
  end

  rule :elif_stmt do
    match(:elif_keyword, :cond, ':', :nested_oneline_stmt, :elif_stmt) {
      |_,cond,_,stmt,elif|
      IfNode.new(cond, stmt, elif_else=elif)
    }
    match(:elif_keyword, :cond, ':', :nested_oneline_stmt) {
      |_,cond,_,stmt|
      IfNode.new(cond, stmt)
    }

    match(:elif_keyword, :cond, :nested_stmts_block, :elif_stmt) {
      |_,cond,stmts,elif|
      IfNode.new(cond, stmts, elif_else=elif)
    }
    match(:elif_keyword, :cond, :nested_stmts_block) {
      |_,cond,stmts|
      IfNode.new(cond, stmts)
    }

    match(:else_stmt)
  end

  rule :else_stmt do
    match(:else_keyword, ':', :nested_oneline_stmt) {
      |_,_,stmt|
      cond = BoolNode.new(true)  # always eval to true
      IfNode.new(cond, stmt)
    }

    match(:else_keyword, :nested_stmts_block) {
      |_,stmts|
      cond = BoolNode.new(true)  # always eval to true
      IfNode.new(cond, stmts)
    }
  end

  rule :while_stmt do
    match('while', :cond, ':', :nested_oneline_stmt) {
      |_,cond,_,stmt|
      WhileNode.new(cond, stmt)
    }

    match('while', :cond, :nested_stmts_block) {
      |_,cond,stmts|
      WhileNode.new(cond, stmts)
    }
  end
end
