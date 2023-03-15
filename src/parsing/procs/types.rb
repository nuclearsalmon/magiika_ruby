#!/usr/bin/env ruby

# ✨ TYPES
# ------------------------------------------------------------------------------
TYPES_PROC = Proc.new do
  rule :name do
    match(/([A-Za-z][A-Za-z_0-9]*)/)
  end
  
  rule :value do
    match(:literal)
    match(:fn_call)
    match(:var)
    match("(", :cond, ")")      {|_,cond,_| cond}
  end
  
  rule :literal do
    match("empty")              {EmptyNode.new}
    match(:flt)
    match(:int)
    match(:bool)
    match(:str)
  end

  rule :built_in_type do
    match("empty")
    match("magic")
    match("bool")
    match("flt")
    match("int")
    match("str")
    match("lst")
  end

  rule :type do
    match(:built_in_type)
    match(:name)
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
    match(/'([^'\\]*(?:\\.[^'\\]*)*)'/) {|str| StrNode.new(str[1..-2])}
  end
end
