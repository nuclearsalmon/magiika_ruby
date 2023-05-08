#!/usr/bin/env ruby

# ✨ COMMONS
# ------------------------------------------------------------------------------
COMMONS_PROC = Proc.new do
  rule :l_curbracket do
    match('{')
    match(:eol, '{')
  end

  rule :r_curbracket do
    match('}')
    match('}', :eol)
  end

  rule :curbracket_block do
    match(:l_curbracket, :r_curbracket)
  end

  rule :l_parenthesis do
    match('(')
    match(:eol, '(')
  end

  rule :r_parenthesis do
    match(')')
    match(')', :eol)
  end

  rule :parenthesis_block do
    match(:l_parenthesis, :r_parenthesis)
  end

  rule :l_sqbracket do
    match('[')
    match(:eol, ']')
  end

  rule :r_sqbracket do
    match(']')
    match(']', :eol)
  end

  rule :sqbracket_block do
    match(:l_sqbracket, :r_sqbracket)
  end
end
