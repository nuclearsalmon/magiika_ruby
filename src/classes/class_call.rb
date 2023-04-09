#!/usr/bin/env ruby


class ClassAccessStmt < BaseNode
  def initialize(name, member_name, value=nil)
    @name, @member_name, @value = name, member_name, value

    super()
  end

  def eval(scope)
    cls = scope.get(@name).unwrap_all()
    if !(cls.class <= ClassNode || cls.class <= ClassInstanceNode)
      raise Error::UndefinedVariable.new(@name)
    end

    if @value != nil
      return cls.set(@member_name, @value, scope)
    else
      return cls.get(@member_name, scope)
    end
  end
end

class ClassFunctionCallStmt < BaseNode
  def initialize(name, fn_name, args)
    @name, @fn_name, @args = name, fn_name, args

    super()
  end

  def eval(scope)
    cls = scope.get(@name).unwrap_all()
    if !(cls.class <= ClassNode || cls.class <= ClassInstanceNode)
      raise Error::UndefinedVariable(@name)
    end
    
    return cls.call(@fn_name, @args, scope)
  end
end

