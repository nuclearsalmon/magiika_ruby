#!/usr/bin/env ruby


class ClassDefStmt < BaseNode
  attr_reader :attribs

  def initialize(attribs, name, stmts, inherit_type)
    @attribs, @name, @stmts, @inherit_type = attribs, name, stmts, inherit_type 
  end

  def eval(scope)
    if @inherit_type != nil
      inherit_type = @inherit_type.eval(scope)  # resolve
    end
    cls = ClassNode.new(@name, @stmts, inherit_type)
    meta = MetaNode.new(@attribs, cls, cls)
    scope.add(@name, meta)
  end
end


class ConstructorDefStmt < FunctionDefStmt
  def initialize(params=[], stmts=StmtsNode.new([]))
    # inject return
    stmts = StmtsNode.new(
      stmts.unwrap.concat(
        [ReturnStmtNode.new(RetrieveVariableStmt.new('self'))]
      )
    )
    
    super([], 'init', params, [], RetrieveVariableStmt.new('self'), stmts)
  end
end


class ClassInitStmt < BaseNode
  def initialize(name, args)
    @name, @args = name, args

    super()
  end

  def eval(scope)
    meta = scope.get(@name)
    cls = meta.unwrap()
    raise Error::UndefinedVariable(@name) if !(cls.class <= ClassNode)
    
    return ClassInstanceNode.new(cls, args, scope)
  end
end
