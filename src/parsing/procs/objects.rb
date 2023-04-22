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

  rule :assign_var do
    match(:name, "=", :expr) {
      |name,_,value|
      AssignVariable.new(name, value)
    }
  end

  rule :reassign_var do
    # special declaration syntax
    # FIXME: This should later be inside a statement, not freestanding.
    #        This is temporary just for testing purposes.
    match(:name, ":=", :expr) {
      |name,_,value| 
      RedeclareVariable.new(name, value)
    }
  end

  rule :extended_assign_var do
    match(:assign_var)
    match(:reassign_var)
  end

  rule :retrieve_var do
    match(:eol)  {nil}  # this is a hack but it fixes :name matching :eol variants
    match(:name) {|name| RetrieveVariable.new(name)}
  end


  # ✨ Access stacking
  # --------------------------------------------------------

  rule :member do
    match(:fn_call)
    match(:retrieve_var)
  end

  rule :member_access do
    match(:member, '.', :member_access) {
      |source,_,action|
      MemberAccessStmt.new(source, action)
    }
    match(:member)
  end

  rule :member_assign do
    match(:member_access, "=", :expr) {
      |access,_,value|
      MemberAssignStmt.new(access, value)
    }
    match(:assign_var)
  end
end
