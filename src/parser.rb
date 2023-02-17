#!/usr/bin/env ruby

require 'logger'
require './src/rdparse.rb'
require './src/types.rb'
require './src/program.rb'
require './src/scope.rb'
require './src/variables.rb'


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
      token(/(\n|;)+/)              {|_| :eol}         # eol marker

      # comments
      token(/#.*$/)
      token(/\/\/.*$/)
      token(/\/\*([^*]|\r?\n|(\*+([^*\/]|\r?\n)))*\*+\//)
      
      # literals
      token(/\d+\.\d+/)             {|t| t.to_f}        # float literal
      token(/\d+/)                  {|t| t.to_i}        # int literal
      token(/true/)                 {|t| :true}         # bool literal
      token(/false/)                {|t| :false}        # bool literal

      # multi-character operators
      token(/(:=|\|\||&&)/)         {|t| t}             # := || &&

      # operators
      token(/(=|\+|-|\*|\/|%|&|!|<|>)/) {|t| t}         # = + - * / % & ! < >

      # symbols
      token(/(\[|\]|\(|\)|\{|\}|,|\.|:)/) {|t| t}       # () [] {} , . :
      
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
        match(:nested_stmt)
      end

      rule :nested_stmt do
        match(:declare_stmt)
        match(:assign_stmt)
        match(:condition)
        match(:expression)
      end


      # ✨ TYPES
      # ------------------------------------------------------------------------
      
      rule :value do
        match(:literal)
        match("empty")              {EmptyNode.new}
        match(:variable)
      end
      
      rule :literal do
        match(:flt)
        match(:int)
        match(:bool)
      end

      rule :int do
        match(Integer)              {|int| IntNode.new(int)}
      end

      rule :flt do
        match(Float)                {|flt| FltNode.new(flt)}
      end

      rule :bool do
        match(:true)                {|_| BoolNode.new(true)}
        match(:false)               {|_| BoolNode.new(false)}
      end


      # ✨ VARIABLES
      # ------------------------------------------------------------------------

      rule :name do
        match(/([A-Za-z][A-Za-z_\-0-9]*)/)
      end

      rule :built_in_type do
        match("magic")
        match("bool")
        match("int")
        match("flt")
        match("str")
        match("chr")
        match("lst")
      end

      rule :declare_stmt do
        # special declaration syntax
        #FIXME: This should later be inside a statement, not freestanding.
        #       This is temporary just for testing purposes.
        match(:name, ":=", :value) {
          |name,_,value| 
          RedeclareVariable.new(name, value, scope_handler)
        }
        match(:name, ":=", :expression) {
          |name,_,value| 
          RedeclareVariable.new(name, value, scope_handler)
        }

        # static typing
        match(:built_in_type, ":", :name, "=", :expression) {
          |type,_,name,_,value| 
          DeclareVariable.new(type, name, value, scope_handler)
        }
        match(:built_in_type, ":", :name, "=", :value) {
          |type,_,name,_,value| 
          DeclareVariable.new(type, name, value, scope_handler)
        }
        match(:built_in_type, ":", :name) {
          |type,_,name|
          DeclareVariable.new(type, name, scope_handler)
        }

        # eol handling
        match(":", :eol)            {nil}

        # dynamic typing (`magic' type 🌟)
        match(":", :name, "=", :expression) {
          |_,name,_,value| 
          DeclareVariable.new("magic", name, value, scope_handler)
        }
        match(":", :name, "=", :value) {
          |_,name,_,value| 
          DeclareVariable.new("magic", name, value, scope_handler)
        }
        match(":", :name)           {|_,name|
          DeclareVariable.new("magic", name, scope_handler)
        }
      end

      rule :assign_stmt do
        match(:name, "=", :expression) {
          |name,_,value| 
          AssignVariable.new(name, value, scope_handler)
        }

        match(:name, "=", :value) {
          |name,_,value| 
          AssignVariable.new(name, value, scope_handler)
        }
      end

      rule :variable do
        match(:name)                {|name|
          RetrieveVariable.new(name, scope_handler)
        }
      end


      # ✨ EXPRESSIONS
      # ------------------------------------------------------------------------

      rule :expression do
        match(:expression, "+", :value) {
          |l,op,r| ExpressionNode.new(l, op, r)
        }
        match(:value, "+", :value) {
          |l,op,r| ExpressionNode.new(l, op, r)
        }
        match(:value, "+", :expression) {
          |l,op,r| ExpressionNode.new(l, op, r)
        }
        match("+", :value) {
          |op,r| ExpressionNode.new(EmptyNode.get_default_instance, op, r)
        }

        match(:expression, "-", :value) {
          |l,op,r| ExpressionNode.new(l, op, r)
        }
        match(:value, "-", :value) {
          |l,op,r| ExpressionNode.new(l, op, r)
        }
        match(:value, "-", :expression) {
          |l,op,r| ExpressionNode.new(l, op, r)
        }
        match("-", :value) {
          |op,r| ExpressionNode.new(EmptyNode.get_default_instance, op, r)
        }

        match(:value)
      end

      
      # ✨ CONDITIONS
      # ------------------------------------------------------------------------

      rule :condition do
        match(:and_condition)
      end

      rule :and_condition do
        match(:and_condition, /and|&&/, :or_condition) {
          |l,op,r| ConditionNode.new(l, op, r)
        }
        match(:or_condition)
      end

      rule :or_condition do
        match(:or_condition, /or|\|\|/, :condition_fallback) {
          |l,op,r| ConditionNode.new(l, op, r)
        }
        match(:condition_fallback)
      end

      rule :condition_fallback do
        match(:expression)
      end
      
    end
  end
end
