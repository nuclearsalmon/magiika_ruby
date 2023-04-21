#!/usr/bin/env ruby


# ✨ OBJECTS
# ------------------------------------------------------------------------------
OBJECTS_PROC = Proc.new do
  # ✨ Variable declaration
  # --------------------------------------------------------

  rule :magic_declare_var do
    match(":", :name, "=", :cond) {
      |_,name,_,value| 
      DeclareVariable.new("magic", name, value)
    }
    match(":", :name) {
      |_,name| 
      DeclareVariable.new("magic", name)
    }
  end

  rule :typed_declare_var do
    match(:name, ":", :name, "=", :expr) {
      |type,_,name,_,value| 
      DeclareVariable.new(type, name, value)
    }
    match(:name, ":", :name) {
      |type,_,name|
      DeclareVariable.new(type, name)
    }
  end

  rule :declare_var do
    match(:typed_declare_var)
    match(:magic_declare_var)
  end


  # ✨ Variable assignment and retrieval
  # --------------------------------------------------------

  rule :reassign_var do
    # special declaration syntax
      # FIXME: This should later be inside a statement, not freestanding.
      #        This is temporary just for testing purposes.
      match(:name, ":=", :expr) {
        |name,_,value| 
        RedeclareVariable.new(name, value)
      }
    end

  rule :assign_var do
    match(:name, "=", :expr) {
      |name,_,value|
      AssignVariable.new(name, value)
    }
  end

  rule :retrieve_var do
    match(:eol)  {nil}  # this is a hack but it fixes :name matching :eol variants
    match(:name) {|name| RetrieveVariable.new(name)}
  end


  # ✨ Access stacking
  # --------------------------------------------------------

  rule :member do
    match(:fn_call)
    match(:assign_var)
    match(:retrieve_var)
  end

  rule :member_access do
    match(:member_access, '.', :member_access) {
      |source,_,action|
      MemberAccessStmt.new(source, action)
    }
    match(:member)
  end
end
