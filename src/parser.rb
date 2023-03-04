#!/usr/bin/env ruby

require_relative './error.rb'
require_relative './rdparse.rb'
require_relative './safety.rb'
require_relative './nodes.rb'
require_relative './program.rb'
require_relative './scope.rb'
require_relative './variable.rb'

require 'logger'


class MagiikaParser
  attr_reader :parser

  def initialize
    @scope_handler = ScopeHandler.new
    # create a variable so we can use the ScopeHandler inside the parser block
    scope_handler = @scope_handler
    
    @parser = Parser.new("Magiika") do
      # ✨ TOKENS
      # ------------------------------------------------------------------------

      # whitespace
      token(/(\n|;)+/)              {|_| :eol}          # eol marker

      # comments
      token(/#.*$/)
      #token(/\/\/.*$/)
      token(/\/\*([^*]|\r?\n|(\*+([^*\/]|\r?\n)))*\*+\//)
      
      # literals
      token(/\d+\.\d+/)             {|t| t.to_f}        # flt literal
      token(/\d+/)                  {|t| t.to_i}        # int literal
      token(/true/)                 {|t| :true}         # bool literal
      token(/false/)                {|t| :false}        # bool literal
      token(/"([^"\\]*(?:\\.[^"\\]*)*)"/) {|t| t}       # str literal

      # multi-character operators      
      token(/(\|\||&&|!\||!&|!^)/)  {|t| t}
      token(/(==|!=|>=|<=)/)        {|t| t}
      token(/(:=)/)                 {|t| t}
      token(/(\+\+|--|\/\/|<<|>>)/) {|t| t}

      # single-character operators
      token(/(=|\+|-|\*|\/|%|&|!|<|>)/) {|t| t}

      # symbols
      token(/(\[|\]|\(|\)|\{|\}|,|\.|:|\$)/) {|t| t}
      
      # names
      token(/[A-Za-z][A-Za-z_\-0-9]*/) {|t| t}

      # whitespace (run this last to allow for whitespace-sensitive tokens)
      token(/(\ |\t)+/)                                 # space or tab


      # ✨ CORE RULES
      # ------------------------------------------------------------------------

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

        match(:declare_stmt)
        match(:assign_stmt)

        match(:cond)
      end



      # ✨ TYPES
      # ------------------------------------------------------------------------

      rule :name do
        match(/([A-Za-z][A-Za-z_0-9]*)/)
      end
      
      rule :value do
        match(:literal)
        match("empty")              {EmptyNode.new}
        match(:var)
        match("(", :cond, ")")      {|_,cond,_| cond}
      end
      
      rule :literal do
        match(:flt)
        match(:int)
        match(:bool)
        match(:str)
      end

      rule :built_in_type do
        match("magic")
        match("bool")
        match("flt")
        match("int")
        match("str")
        match("lst")
      end

      rule :flt do
        match(Float)                {|flt| FltNode.new(flt)}
      end

      rule :int do
        match(Integer)              {|int| IntNode.new(int)}
      end

      rule :bool do
        match(:true)                {|_| BoolNode.new(true)}
        match(:false)               {|_| BoolNode.new(false)}
      end

      rule :str do
        match(/"([^"\\]*(?:\\.[^"\\]*)*)"/) {|str| StrNode.new(str[1..-2])}
      end


      # ✨ VARIABLES
      # ------------------------------------------------------------------------

      rule :var do
        match(:name) {|name| RetrieveVariable.new(name, scope_handler)}
      end

      rule :declare_stmt do
        # special declaration syntax
        #FIXME: This should later be inside a statement, not freestanding.
        #       This is temporary just for testing purposes.
        match(:name, ":=", :expr) {
          |name,_,value| 
          RedeclareVariable.new(name, value, scope_handler)
        }

        match(:magic_declare_stmt)
        match(:static_declare_stmt)
      end

      rule :magic_declare_stmt do
        match(":", :name, "=", :cond) {
          |_,name,_,value| 
          DeclareVariable.new("magic", name, value, scope_handler)
        }

        # eol handling
        match(":", :eol)           {nil}

        match(":", :name) {
          |_,name| 
          DeclareVariable.new("magic", name, scope_handler)
        }
      end

      rule :static_declare_stmt do
        match(:built_in_type, ":", :name, "=", :expr) {
          |type,_,name,_,value| 
          DeclareVariable.new(type, name, value, scope_handler)
        }
        match(:built_in_type, ":", :name) {
          |type,_,name|
          DeclareVariable.new(type, name, scope_handler)
        }
      end

      rule :assign_stmt do
        match(:name, "=", :expr) {
          |name,_,value|
          AssignVariable.new(name, value, scope_handler)
        }
      end


      # ✨ CONDITIONS
      # ------------------------------------------------------------------------

      rule :cond do  # exists for the sake of readability
        match(:or_cond)
      end

      rule :or_cond do
        match(:or_cond, "|", :and_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :bitwise_or, r)
        }
        match(:or_cond, "||", :and_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :or, r)
        }
        match(:or_cond, "or", :and_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :or, r)
        }
        match(:and_cond)
      end

      rule :and_cond do
        match(:and_cond, "&", :xnor_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :bitwise_and, r)
        }
        match(:and_cond, "&&", :xnor_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :and, r)
        }
        match(:and_cond, "and", :xnor_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :and, r)
        }
        match(:xnor_cond)
      end

      rule :xnor_cond do
        match(:xnor_cond, "!^", :xor_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :bitwise_xnor, r)
        }
        match(:xnor_cond, "xnor", :xor_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :xnor, r)
        }
        match(:xor_cond)
      end

      rule :xor_cond do
        match(:xor_cond, "^", :nor_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :bitwise_xor, r)
        }
        match(:xor_cond, "xor", :nor_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :xor, r)
        }
        match(:nor_cond)
      end

      rule :nor_cond do
        match("!|", :nand_cond) {
          |l,op,r|
          UnaryExpressionNode.new(:bitwise_nor, r)
        }
        match(:nor_cond, "!|", :nand_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :bitwise_nor, r)
        }
        match(:nor_cond, "nor", :nand_cond) {
          |l,op,r|
          BinaryExpressionNode.new(l, :nor, r)
        }
        match(:nand_cond)
      end

      rule :nand_cond do
        match(:nand_cond, "!&", :expr) {
          |l,op,r|
          BinaryExpressionNode.new(l, :bitwise_nand, r)
        }
        match(:nand_cond, "nand", :expr) {
          |l,op,r|
          BinaryExpressionNode.new(l, :nand, r)
        }
        match(:comp)
      end

      rule :comp_op do
        match("==")
        match("!=")
        match(">")
        match("<")
        match(">=")
        match("<=")
      end

      rule :comp do
        match(:expr, :comp_op, :expr) {|l,op,r| BinaryExpressionNode.new(l, op, r)}
        match("!", :cond)           {|_,value| BooleanInverterNode.new(value)}
        match("not", :cond)         {|_,value| BooleanInverterNode.new(value)}
        match(:expr)
      end


      # ✨ EXPRESSIONS
      # ------------------------------------------------------------------------
      
      # expression starting point. will propagate down
      # to higher and higher precedence, as with all the other rules.
      rule :expr do
        match(:expr, "+", :term) {
          |l,op,r|
          BinaryExpressionNode.new(l, op, r)
        }
        match(:expr, "-", :term) {
          |l,op,r|
          BinaryExpressionNode.new(l, op, r)
        }
        match(:term)
      end

      # higher precedence expressions
      rule :term do
        match(:term, "*", :unary_prefix_op) {
          |l,op,r|
          BinaryExpressionNode.new(l, op, r)
        }
        match(:term, "/", :unary_prefix_op) {
          |l,op,r|
          BinaryExpressionNode.new(l, op, r)
        }
        match(:term, "%", :unary_prefix_op) {
          |l,op,r|
          BinaryExpressionNode.new(l, op, r)
        }
        match(:term, "//", :unary_prefix_op) {
          |l,op,r|
          BinaryExpressionNode.new(l, :int_div, r)
        }
        match(:unary_prefix_op)
      end

      rule :unary_prefix_op do
        match("-", :unary_postfix_op) {
          |op,obj|
          UnaryExpressionNode.new(op, obj)
        }
        match("++", :unary_postfix_op) {
          |_,obj|
          UnaryExpressionNode.new(:pre_inc, obj)
        }
        match("--", :unary_postfix_op) {
          |_,obj|
          UnaryExpressionNode.new(:pre_dec, obj)
        }
        match(:unary_postfix_op)
      end

      rule :unary_postfix_op do
        match(:value, "++") {
          |obj,_|
          UnaryExpressionNode.new(:post_inc, obj)
        }
        match(:value, "--") {
          |obj,_|
          UnaryExpressionNode.new(:post_dec, obj)
        }
        match(:value)
      end


      # ✨ CONTROL FLOW
      # ------------------------------------------------------------------------

      rule :elif_keyword do
        match(:eol, "elif")
        match("elif")
      end
      
      rule :else_keyword do
        match(:eol, "else")
        match("else")
      end

      rule :l_sqbracket do
        match("{")
        match(:eol, "{")
      end

      rule :r_sqbracket do
        match("}")
        match("}", :eol)
      end

      rule :stmts_block do
        match(:l_sqbracket, :stmts, :r_sqbracket) {
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


      # ✨ LIBRARY CALLS
      # ------------------------------------------------------------------------

      rule :syslib_call do
        match("\$", :cond) {|_,obj| PrintNode.new(obj)}
      end
    end
  end
end
