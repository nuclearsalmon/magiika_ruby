#!/usr/bin/env ruby

# ✨ EXPRESSIONS
# ------------------------------------------------------------------------------
EXPRESSIONS_PROC = Proc.new do
  rule :expr do
    match(:expr, '+', :term) {
      |l,op,r|
      BinaryExpressionNode.new(l, :add, r)
    }
    match(:expr, '-', :term) {
      |l,op,r|
      BinaryExpressionNode.new(l, :sub, r)
    }
    match(:term)
  end

  # higher precedence expressions
  rule :term do
    match(:term, '*', :unary_prefix_op) {
      |l,op,r|
      BinaryExpressionNode.new(l, :mult, r)
    }
    match(:term, '/', :unary_prefix_op) {
      |l,op,r|
      BinaryExpressionNode.new(l, :div, r)
    }
    match(:term, '%', :unary_prefix_op) {
      |l,op,r|
      BinaryExpressionNode.new(l, :mod, r)
    }
    match(:term, '//', :unary_prefix_op) {
      |l,op,r|
      BinaryExpressionNode.new(l, :idiv, r)
    }
    match(:unary_prefix_op)
  end

  rule :unary_prefix_op do
    match('-', :unary_postfix_op) {
      |op,obj|
      UnaryExpressionNode.new(:sub, obj)
    }
    match('++', :unary_postfix_op) {
      |_,obj|
      UnaryExpressionNode.new(:pre_inc, obj)
    }
    match('--', :unary_postfix_op) {
      |_,obj|
      UnaryExpressionNode.new(:pre_dec, obj)
    }
    match(:unary_postfix_op)
  end

  rule :unary_postfix_op do
    match(:value, '++') {
      |obj,_|
      UnaryExpressionNode.new(:post_inc, obj)
    }
    match(:value, '--') {
      |obj,_|
      UnaryExpressionNode.new(:post_dec, obj)
    }
    match(:value)
  end
end
