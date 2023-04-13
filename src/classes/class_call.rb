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
      return cls.set(@member_name, @value.eval(scope), scope)
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

class MemberAccessStmt < TypeNode
  attr_reader :from_obj, :member_stmt
  
  def initialize(from_obj, member_stmt)
    @from_obj, @member_stmt = from_obj, member_stmt
    
    super()
  end

  private
  def verify_cls(obj)
    if !(obj.class <= ClassNode or obj.class <= ClassInstanceNode)
      raise Error::MismatchedType.new(obj, [ClassNode, ClassInstanceNode])
    end
  end
  public

  def unwrap_eval(scope)
    # get if string (identifer name), eval if something else (member access stmt)
    obj = @from_obj.class <= String ? scope.get(@from_obj) : @from_obj.eval(scope)
    verify_cls(obj.unwrap_class(MagicNode, incl_self=false))

    member = @member_stmt
    while member.class <= MemberAccessStmt
      obj = obj.get(member.name)
      verify_cls(obj.unwrap_class(MagicNode, incl_self=false))
      member = member.member_stmt
    end

    return obj.run(scope, @member_stmt)
  end

  def eval(scope)
    return unwrap_eval(scope).eval(scope)
  end

  def bool_eval?(scope)
    return unwrap_eval(scope).bool_eval?(scope)
  end

  def output(scope)
    return unwrap_eval(scope).output(scope)
  end
end
