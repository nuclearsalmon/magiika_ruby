#!/usr/bin/env ruby


class ClassNode < TypeNode
  attr_reader :name, :inherit_cls
  attr_reader :defined, :define
  attr_reader :cls_scope, :instance_stmts, :constructor_stmts

  DEFAULT_CONSTRUCTOR_STMT = ConstructorDefStmt.new().freeze

  def initialize(name, stmts, inherit_cls)
    @name               = name
    @stmts              = stmts  # unwrapped stmts array
    @inherit_cls        = inherit_cls

    # verify inherit
    if @inherit_cls != nil && !(@inherit_cls.class <= ClassNode)
      raise Error::MismatchedType.new(inherit_cls, ClassNode)
    end
    
    @defined            = false
    @constructor_stmts  = []
    @instance_stmts     = []
    @cls_scope          = {:@scope_type => :cls_base}
  end

  def define(scope)
    return if @defined
    @cls_scope['this'] = MetaNode.new([:const], self, self)
    
    # ensure defined inherit
    if @inherit_cls != nil
      @inherit_cls.define(scope)
    end

    @stmts.each {
      |stmt|
      next if stmt == :eol_tok or stmt == nil
      
      if stmt.class <= ConstructorDefStmt
        @constructor_stmts << stmt
      elsif stmt.class <= FunctionDefStmt
        if stmt.attribs.include?(:stat)
          # transform to constructor
          if stmt.name == 'init'
            # safecheck return value
            if ![nil, self].include?(stmt.ret_type)
              raise Error::MismatchedType.new(stmt.ret_type, self)
            end
  
            new_stmt = ConstructorDefStmt.new(stmt.params, stmt.stmts)
            @constructor_stmts << new_stmt
          else
            scope.exec_scope(@cls_scope) { stmt.eval(scope) }
          end
        else
          @instance_stmts << stmt
        end
      elsif stmt.class <= ClassDefStmt
        scope.exec_scope(@cls_scope) { stmt.eval(scope) }
      elsif stmt.class <= DeclareVariableStmt
        if stmt.attribs.include?(:stat)
          scope.exec_scope(@cls_scope) { stmt.eval(scope) }
        else
          @instance_stmts << stmt
        end
      else
        expected = [ConstructorDefStmt, FunctionDefStmt, ClassDefStmt, DeclareVariableStmt]
        raise Error::MismatchedType.new(stmt, expected)
      end
    }

    # Define default constructor if missing
    if @constructor_stmts.length <= 0
      @constructor_stmts << DEFAULT_CONSTRUCTOR_STMT
    end

    @defined = true
  end

  def run(stmt, scope)
    define(scope)

    scopes = [
      @inherit_cls.cls_scope,
      @cls_scope
    ]

    return scope.exec_scopes(scopes) {
      next stmt.eval(scope)
    }
  end

  def self.type
    return 'cls'
  end

  def type
    return @name
  end
end
