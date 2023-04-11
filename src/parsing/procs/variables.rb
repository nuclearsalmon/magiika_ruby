#!/usr/bin/env ruby

# ✨ VARIABLES
# ------------------------------------------------------------------------------
VARIABLES_PROC = Proc.new do
  rule :var do
    match(:eol)  {nil}  # this is a hack but it fixes a really annoying issue.
    match(:name) {|name| RetrieveVariable.new(name)}
  end

  rule :declare_stmt do
    # special declaration syntax
    # FIXME: This should later be inside a statement, not freestanding.
    #        This is temporary just for testing purposes.
    match(:name, ":=", :expr) {
      |name,_,value| 
      RedeclareVariable.new(name, value)
    }

    match(:magic_declare_stmt)
    match(:typed_declare_stmt)
  end

  rule :magic_declare_stmt do
    match(":", :name, "=", :cond) {
      |_,name,_,value| 
      DeclareVariable.new("magic", name, value)
    }

    # eol handling
    match(":", :eol)           {nil}

    match(":", :name) {
      |_,name| 
      DeclareVariable.new("magic", name)
    }
  end

  rule :typed_declare_stmt do
    match(:name, ":", :name, "=", :expr) {
      |type,_,name,_,value| 
      DeclareVariable.new(type, name, value)
    }
    match(:name, ":", :name) {
      |type,_,name|
      DeclareVariable.new(type, name)
    }
  end

  rule :assign_stmt do
    match(:name, "=", :expr) {
      |name,_,value|
      AssignVariable.new(name, value)
    }
  end
end
