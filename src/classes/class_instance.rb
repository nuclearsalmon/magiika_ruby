class StaticNode < ContainerTypeNode
  def eval(scope)
    return @value.eval(scope)
  end

  def bool_eval?(scope)
    return @value != EmptyNode.get_default
  end

  def output
    return @value.output
  end

  def self.type
    return "static"
  end
end


class ClassNode < TypeNode
  attr_reader :name, :parent_cls_name
  attr_reader :defined, :define
  attr_reader :cls_scope, :inst_stmts, :constructor_scope

  def initialize(name, stmts, parent_cls_name)
    @name                 = name
    @stmts                = stmts  # unwrapped stmts
    @parent_cls_name      = parent_cls_name
    
    @defined              = false
    @cls_scope            = {:@scope_type => :cls_base}
    @inst_stmts           = []
    @constructor_scope    = {:@scope_type => :cls_constructors}
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

      @cls_scope = parent.cls_scope.clone    # shallow
      @inst_stmts = parent.inst_stmts.clone  # shallow
    end

    @stmts.each {
      |stmt|
      puts "\nstmt:"
      p stmt

      if stmt.class <= ConstructorDefStmt
        p 1
        scope.exec_scope(@constructor_scope) { stmt.eval(scope) }
      elsif stmt.class <= StaticNode or stmt.class <= FunctionDefStmt
        p 2
        scope.exec_scope(@cls_scope) { stmt.eval(scope) }
      else
        p 3
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

    return scope.exec_scope(@cls_scope) {
      next scope.get(name)
    }
  end

  def set(name, value, scope)
    define(scope)

    # FIXME SAFEGUARD AGAINST SETTING NEW VARIABLES
    return scope.exec_scope(@cls_scope) {
      next scope.set(name, value, replace=true, retrieve=false)
    }
  end

  def call(name, args, scope)
    define(scope)

    scopes = [
      @cls_scope,
      {:@scope_type => :fn_call, "self" => self, "this" => self}
    ]

    return scope.exec_scopes(scopes) {
      next FunctionCallStmt.new(name, args).eval(scope)
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

    return if @instantiated

    cls.inst_stmts.each {
      |stmt|
      if !(stmt.class <= StaticNode)
        scope.exec_scope(@instance_scope) { stmt.eval(scope) }
      end
    }

    scopes = [
      cls.cls_scope,
      @instance_scope,
      cls.constructor_scope,
      {:@scope_type => :fn_call, "self" => self, "this" => @cls}
    ]

    scope.exec_scopes(scopes) {
      fn_call = FunctionCallStmt.new(:init, args)
      fn_call.eval(scope)
    }

    @instantiated = true
  end

  # ⭐ PUBLIC
  # --------------------------------------------------------
  public

  def initialize(cls, args, scope)
    @cls = cls

    @instantiated = false
    @instance_scope = {:@scope_type => :cls_instance}

    instantiate(args, scope)
    # no super() - no freeze
  end

  def method_missing(method_name, *args, &block)
    @cls.public_send(method_name, *args, &block)
  end

  def get(name, scope)
    raise Error::NotInitialized.new() if !@instantiated

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
    raise Error::NotInitialized.new() if !@instantiated

    scopes = [
      @cls.cls_scope,
      @instance_scope
    ]

    return scope.exec_scopes(scopes) {
      next scope.set(name, value, replace=true, retrieve=false)
    }
  end

  def call(name, args, scope)
    raise Error::NotInitialized.new() if !@instantiated

    scopes = [
      @cls.cls_scope,
      @instance_scope,
      {:@scope_type => :fn_call, "self" => self, "this" => @cls}
    ]

    return scope.exec_scopes(scopes) {
      fn_call = FunctionCallStmt.new(:init, args)
      next fn_call.eval(scope)
    }
  end

  def self.type
    return "cls"
  end

  def type
    return @cls.name
  end
end
