#!/usr/bin/env ruby


class ClassInstanceNode < TypeNode
  attr_reader :cls
  attr_reader :instantiated

  def initialize(cls, args, scope)
    @cls                = cls
    @constructor_scope  = {:@scope_type => :cls_init}
    @instance_scope     = {:@scope_type => :cls_inst}
    
    instantiate(args, scope)
  end

  # ⭐ PRIVATE
  # --------------------------------------------------------
  private

  def instantiate(args, scope)
    @cls.define(scope)

    if @cls.abstract
      raise Error::Magiika.new(
        'Instantiating a class with abstract variables or functions is not allowed.')
    end

    # define self in scope
    @instance_scope['self'] = MetaNode.new([:const], self, self)

    # define scopelist
    scopes = [
      @cls.cls_scope,
      @instance_scope
    ]

    # evaluate instance statements
    scope.exec_scopes(scopes) { 
      @cls.instance_stmts.each {|stmt| stmt.eval(scope)}
    }

    # add constructor scope to scopelist
    scopes << @constructor_scope
    # evaluate constructor statements
    scope.exec_scopes(scopes) { 
      @cls.constructor_stmts.each {|stmt| stmt.eval(scope)}
    }

    # call constructor
    scope.exec_scopes(scopes) {
      FunctionCallStmt.new('init', args).eval(scope)
    }
  end

  # ⭐ PUBLIC
  # --------------------------------------------------------
  public

  def method_missing(method_name, *args, &block)
    @cls.public_send(method_name, *args, &block)
  end

  def run(stmt, scope)
    scopes = []
    inherited_scopes = @cls.get_inherited_scopes()
    if inherited_scopes != nil
      inherited_scopes.each {|scope| scopes << scope}
    end
    scopes << @cls.cls_scope
    scopes << @instance_scope

    return scope.exec_scopes(scopes) {
      next stmt.eval(scope)
    }
  end

  def self.type
    return 'cls'
  end

  def type
    return @cls.name
  end
end
