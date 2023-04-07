#!/usr/bin/env ruby


class ClassAccessStmt < BaseNode
  def initialize(name, member_name)
    @name, @member_name = name, member_name

    super()
  end

  def eval(scope)
    cls = scope.get(@name)
    raise Error::UndefinedVariable(@name) if !(cls.class <= ClassNode)
    
    return cls.get(@member_name, scope)
  end
end

class ClassFunctionCallStmt < BaseNode
  def initialize(name, fn_name, args)
    @name, @fn_name, @args = name, fn_name, args

    super()
  end

  def eval(scope)
    cls = scope.get(@name)
    raise Error::UndefinedVariable(@name) if !(cls.class <= ClassNode)
    
    return cls.call(@fn_name, @args, scope)
  end
end

