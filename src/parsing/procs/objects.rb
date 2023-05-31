#!/usr/bin/env ruby


# ✨ OBJECTS
# ------------------------------------------------------------------------------
OBJECTS_PROC = Proc.new do
  # ✨ Variable declaration
  # --------------------------------------------------------

  rule :declare_var do
    match(:type_ident, :name, '=', :expr) {
      |ident,name,_,value| 
      attribs, type = *ident
      DeclareVariableStmt.new(attribs, type, name, value)
    }
    match(:type_ident, :name) {
      |ident,name|
      attribs, type = *ident
      DeclareVariableStmt.new(attribs, type, name)
    }
  end

  
  # ✨ Variable assignment and retrieval
  # --------------------------------------------------------

  rule :assign_var do
    match(:name, '=', :expr) {
      |name,_,value|
      AssignVariableStmt.new(name, value)
    }
  end

  rule :reassign_var do
    # special declaration syntax
    # FIXME: This should later be inside a statement, not freestanding.
    #        This is temporary just for testing purposes.
    match(:name, ':=', :expr) {
      |name,_,value| 
      ReassignVariableStmt.new(name, value)
    }
  end

  rule :retrieve_var do
    match(:eol)  {nil}  # this is a hack but it fixes :name matching :eol variants
    match(:name) {|name| RetrieveVariableStmt.new(name)}
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
    match(:assign_var)
    match(:member_access, '=', :expr) {
      |access,_,value|
      MemberAssignStmt.new(access, value)
    }
  end
end
