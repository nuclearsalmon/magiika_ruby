#!/usr/bin/env ruby

# ✨ CONDITIONS
# ------------------------------------------------------------------------------
CONDITIONS_PROC = Proc.new do
  rule :cond do  # exists for the sake of readability
    match(:or_cond)
  end

  rule :or_cond do
    match(:or_cond, "|", :and_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :bitwise_or, r)
    }
    match(:or_cond, "||", :and_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :or, r)
    }
    match(:or_cond, "or", :and_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :or, r)
    }
    match(:and_cond)
  end

  rule :and_cond do
    match(:and_cond, "&", :xnor_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :bitwise_and, r)
    }
    match(:and_cond, "&&", :xnor_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :and, r)
    }
    match(:and_cond, "and", :xnor_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :and, r)
    }
    match(:xnor_cond)
  end

  rule :xnor_cond do
    match(:xnor_cond, "!^", :xor_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :bitwise_xnor, r)
    }
    match(:xnor_cond, "xnor", :xor_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :xnor, r)
    }
    match(:xor_cond)
  end

  rule :xor_cond do
    match(:xor_cond, "^", :nor_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :bitwise_xor, r)
    }
    match(:xor_cond, "xor", :nor_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :xor, r)
    }
    match(:nor_cond)
  end

  rule :nor_cond do
    match("!|", :nand_cond) {
      |l,op,r| UnaryExpressionNode.new(:bitwise_nor, r)
    }
    match(:nor_cond, "!|", :nand_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :bitwise_nor, r)
    }
    match(:nor_cond, "nor", :nand_cond) {
      |l,op,r| BinaryExpressionNode.new(l, :nor, r)
    }
    match(:nand_cond)
  end

  rule :nand_cond do
    match(:nand_cond, "!&", :expr) {
      |l,op,r| BinaryExpressionNode.new(l, :bitwise_nand, r)
    }
    match(:nand_cond, "nand", :expr) {
      |l,op,r| BinaryExpressionNode.new(l, :nand, r)
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
    match("!", :cond)             {|_,value| BooleanInverterNode.new(value)}
    match("not", :cond)           {|_,value| BooleanInverterNode.new(value)}
    match(:expr)
  end
end
