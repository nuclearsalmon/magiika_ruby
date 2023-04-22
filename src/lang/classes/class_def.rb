#!/usr/bin/env ruby


class StaticNode < ContainerTypeNode
  def eval(scope)
    return @value.eval(scope)
  end

  def bool_eval?(scope)
    return @value != EmptyNode.get_default
  end

  def output(scope)
    return @value.output(scope)
  end

  def self.type
    return "static"
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
        [ReturnStmtNode.new(RetrieveVariable.new("self"))]
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