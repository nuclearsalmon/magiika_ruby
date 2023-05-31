#!/usr/bin/env ruby


class ClassDefStmt < BaseNode
  attr_reader :attribs

  def initialize(attribs, name, stmts, inherit_cls)
    @attribs, @name, @stmts, @inherit_cls = attribs, name, stmts, inherit_cls
    freeze
  end

  def eval(scope)
    if @inherit_cls != nil
      inherit_cls = @inherit_cls.eval(scope)  # resolve
    end
    cls = ClassNode.new(@name, @stmts, inherit_cls)
    meta = MetaNode.new(@attribs, cls, cls)
    scope.add(@name, meta)
  end
end


class ConstructorDefStmt < FunctionDefStmt
  def initialize(params=[], stmts=[])
    # inject return
    stmts = stmts.concat([ReturnStmtNode.new(RetrieveVariableStmt.new('self'))])
    
    super([], 'init', params, [], RetrieveVariableStmt.new('self'), stmts)
  end
end


class ClassInitStmt < BaseNode
  def initialize(name, args)
    @name, @args = name, args
    freeze
  end

  def eval(scope)
    meta = scope.get(@name)
    cls = meta.unwrap()
    raise Error::UndefinedVariable(@name) if !(cls.class <= ClassNode)
    
    return ClassInstanceNode.new(cls, args, scope)
  end
end
