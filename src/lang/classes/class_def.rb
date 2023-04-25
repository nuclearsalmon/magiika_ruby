#!/usr/bin/env ruby


class StaticNode < ContainerTypeNode
  def eval(scope)
    raise Error::Magiika.new(\
      'StaticNodes are not meant to be evaluated, they are meant to be unwrapped.')
  end

  def self.type
    return 'static'
  end
end


class ConstNode < ContainerTypeNode
  def eval(scope)
    return @value.eval(scope)
  end

  def self.type
    return 'const'
  end

  def eval(scope)
    return unwrap().eval(scope)
  end
end


class ConstStmt < ConstNode
  def initialize(stmt)
    if stmt.class <= DeclareVariableStmt
      stmt.const = true  # set flag
    else
      raise Error::Magiika.new(\
        'ConstNodes should only be initialized with a variable declaration statement.')
    end
    super(stmt)
  end

  def eval(scope)
    return unwrap().eval(scope)
  end
end


class ClassDefStmt < BaseNode
  def initialize(name, stmts, parent_cls_name=nil)
    @name, @stmts = name, stmts
    @parent_cls_name = parent_cls_name

    super()
  end

  def eval(scope)
    scope.add(@name, ClassNode.new(@name, @stmts, @parent_cls_name))
  end
end


class ConstructorDefStmt < FunctionDefStmt
  def initialize(params=[], stmts=StmtsNode.new([]))
    # inject return
    stmts = StmtsNode.new(
      stmts.unwrap.concat(
        [ReturnStmtNode.new(RetrieveVariableStmt.new("self"))]
      )
    )
    
    super("init", params, "self", stmts)
  end
end


class ClassInitStmt < BaseNode
  def initialize(name, args)
    @name, @args = name, args

    super()
  end

  def eval(scope)
    cls = scope.get(@name)
    raise Error::UndefinedVariable(@name) if !(cls.class <= ClassNode)
    
    return ClassInstanceNode.new(cls, args, scope)
  end
end
