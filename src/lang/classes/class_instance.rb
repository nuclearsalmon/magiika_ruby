#!/usr/bin/env ruby


class ClassNode < TypeNode
  attr_reader :name, :parent_cls_name
  attr_reader :defined, :define
  attr_reader :cls_scope, :inst_stmts, :constructor_scope

  def initialize(name, stmts, parent_cls_name)
    @name                 = name
    @stmts                = stmts  # unwrapped stmts
    @parent_cls_name      = parent_cls_name
    
    @defined            = false
    @cls_scope          = {:@scope_type => :cls_base}
    @inst_stmts         = []
    @constructor_scope  = {:@scope_type => :cls_init}
    # no super() - no freeze
  end

  def define(scope)
    return if @defined
    #raise Error::AlreadyDefined.new(@name) if scope.exist(@name)
    
    # inherit
    if @parent_cls_name != nil
      # get from scope
      parent = nil
      begin
        parent = scope.get(@parent_cls_name)
      rescue Error::UndefinedVariable
        raise Error::UndefinedVariable(@parent_cls_name, \
          "Undefined parent for class `@name'.")
      end
      
      # typecheck
      if !(parent.class <= ClassNode)
        raise Error::MismatchedType(parent, ClassDefStmt)
      end

      @cls_scope   = parent.cls_scope.clone   # shallow
      @inst_stmts     = parent.inst_stmts.clone     # shallow
    end

    @stmts.each {
      |stmt|
      
      if stmt.class <= ConstructorDefStmt
        scope.exec_scope(@constructor_scope) { stmt.eval(scope) }
      elsif stmt.class <= ClassDefStmt
        scope.exec_scope(@cls_scope) { stmt.eval(scope) }
      elsif stmt.class <= StaticNode
        unstatic_stmt = stmt.unwrap()

        if (unstatic_stmt.name == "init") # transform to constructor
          # safecheck return value
          if !["self", "magic"].include?(unstatic_stmt.ret_type)
            raise Error::MismatchedType.new(unstatic_stmt.ret_type, "self")
          end

          scope.exec_scope(@constructor_scope) { 
            ConstructorDefStmt.new(unstatic_stmt.params, unstatic_stmt.stmts).eval(scope)
          }
        else
          scope.exec_scope(@cls_scope) { stmt.eval(scope) }
        end
      else
        @inst_stmts << stmt
      end
    }

    if @constructor_scope.count < 2 # just scope description, no constructor
      scope.exec_scope(@constructor_scope) {
        ConstructorDefStmt.new().eval(scope)
      }
    end

    @defined = true
  end

  def get(name, scope)
    define(scope)

    scopes = [
      @cls_scope,
      {:@scope_type => :fn_call, "this" => self}
    ]

    return scope.exec_scopes(scopes) {
      next scope.get(name)
    }
  end

  def set(name, value, scope)
    define(scope)

    # FIXME SAFEGUARD AGAINST SETTING NEW VARIABLES
    return scope.exec_scope(@cls_scope) {
      next scope.set(name, value, :replace)
    }
  end

  def call(name, args, scope)
    define(scope)

    scopes = [
      @cls_scope,
      {:@scope_type => :cls_ref, "this" => self}
    ]

    return scope.exec_scopes(scopes) {
      next FunctionCallStmt.new(name, args).eval(scope)
    }
  end

  def run(stmt, scope)
    define(scope)

    scopes = [
      @cls_scope,
      {:@scope_type => :cls_run, "this" => self}
    ]

    return scope.exec_scopes(scopes) {
      next stmt.eval(scope)
    }
  end


  def self.type
    return "cls"
  end

  def type
    return @name
  end
end

class ClassInstanceNode < TypeNode
  attr_reader :cls
  attr_reader :instantiated

  # ⭐ PRIVATE
  # --------------------------------------------------------
  private

  def instantiate(args, scope)
    @cls.define(scope)

    scopes = [
      @cls.cls_scope,
      @instance_scope
    ]
    scope.exec_scopes(scopes) { 
      @cls.inst_stmts.each {|stmt| stmt.eval(scope)}
    }

    scopes = [
      @cls.cls_scope,
      @instance_scope,
      @cls.constructor_scope,
      {:@scope_type => :cls_ref, "self" => self, "this" => @cls}
    ]

    scope.exec_scopes(scopes) {
      fn_call = FunctionCallStmt.new("init", args)
      fn_call.eval(scope)
    }
  end

  # ⭐ PUBLIC
  # --------------------------------------------------------
  public

  def initialize(cls, args, scope)
    @cls = cls
    @instance_scope = {:@scope_type => :cls_inst}
    
    instantiate(args, scope)

    # no super() - no freeze
  end

  def method_missing(method_name, *args, &block)
    @cls.public_send(method_name, *args, &block)
  end

  def get(name, scope)
    scopes = [
      @cls.cls_scope,
      @instance_scope,
      {:@scope_type => :fn_call, "self" => self, "this" => @cls}
    ]

    return scope.exec_scopes(scopes) {
      next scope.get(name)
    }
  end

  def set(name, value, scope)
    scopes = [
      @cls.cls_scope,
      @instance_scope
    ]

    return scope.exec_scopes(scopes) {
      next scope.set(name, value, :replace)
    }
  end

  def call(name, args, scope)
    scopes = [
      @cls.cls_scope,
      @instance_scope,
      {:@scope_type => :cls_ref, "self" => self, "this" => @cls}
    ]

    return scope.exec_scopes(scopes) {
      next FunctionCallStmt.new(name, args).eval(scope)
    }
  end

  def run(stmt, scope)
    scopes = [
      @cls.cls_scope,
      @instance_scope,
      {:@scope_type => :cls_run, "self" => self, "this" => @cls}
    ]

    return scope.exec_scopes(scopes) {
      next stmt.eval(scope)
    }
  end

  def self.type
    return "cls"
  end

  def type
    return @cls.name
  end
end
