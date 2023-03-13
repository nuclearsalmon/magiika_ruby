#!/usr/bin/env ruby

# ✨ VARIABLES
# ------------------------------------------------------------------------------
VARIABLES_PROC = Proc.new do
  |scope_handler|
  
  rule :var do
    # match(:eol)  {nil}
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
end
