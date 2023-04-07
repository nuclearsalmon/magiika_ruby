class ClassNode < TypeNode
  attr_reader :name, :parent_cls_name
  attr_reader :defined, :instantiate_static
  attr_reader :cls_scope, :inst_stmts, :static_scope, :constructor_scope

  def initialize(name, stmts, parent_cls_name)
    @name                 = name
    @stmts                = stmts
    @parent_cls_name      = parent_cls_name
    
    @defined              = false
    @cls_scope            = {:@scope_type => :cls_base}
    @inst_stmts           = []

    @instantiated_static  = false
    @static_scope         = {:@scope_type => :cls_static}
    @constructor_scope    = {:@scope_type => :cls_constructors}
    # no super() - no freeze
  end

  # ⭐ PRIVATE
  # --------------------------------------------------------
  private

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

      if stmt.class <= DeclareVariable
        @inst_stmts << stmt
      else
        scope.exec_scope(@cls_scope) { stmt.eval(scope) }
      end
    }

    defined = true
  end

  # ⭐ PUBLIC
  # --------------------------------------------------------
  public

  def instantiate_static(scope)
    define(scope)
    return if @instantiated_static

    @inst_stmts.each {
      |stmt|
      if stmt.class <= ConstructorDefStmt
        scope.exec_scope(@constructor_scope) { stmt.eval(scope) }
      else
        scope.exec_scope(@static_scope) { stmt.eval(scope) }
      end
    }

    if @constructor_scope.count < 2 # just scope description, no constructor
      scope.exec_scope(@constructor_scope) {
        ConstructorDefStmt.new().eval(scope)
      }
    end

    @instantiated_static = true
  end

  def get(name, scope)
    instantiate_static(scope)

    scopes = [
      @cls_scope,
      @static_scope
    ]

    return scope.exec_scopes(scopes) {
      next scope.get(name)
    }
  end

  def set(name, value, scope)
    instantiate_static(scope)

    scopes = [
      @cls_scope,
      @static_scope
    ]

    return scope.exec_scopes(scopes) {
      next scope.set(name, value, replace=true)
    }
  end

  def call(name, args, scope)
    instantiate_static(scope)

    scopes = [
      @cls_scope,
      @static_scope,
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
    return if @instantiated
    
    @cls.instantiate_static(scope)

    scopes = [
      cls.cls_scope,
      cls.static_scope,
      @instance_scope,
      cls.constructor_scope,
      {:@scope_type => :fn_call, "self" => self, "this" => self}
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
      @cls.static_scope,
      @instance_scope
    ]

    return scope.exec_scopes(scopes) {
      next scope.get(name)
    }
  end

  def set(name, value, scope)
    raise Error::NotInitialized.new() if !@instantiated

    scopes = [
      @cls.cls_scope,
      @cls.static_scope,
      @instance_scope
    ]

    return scope.exec_scopes(scopes) {
      next scope.set(name, value, replace=true)
    }
  end

  def call(name, args, scope)
    raise Error::NotInitialized.new() if !@instantiated

    scopes = [
      @cls.cls_scope,
      @cls.static_scope,
      @instance_scope,
      {:@scope_type => :fn_call, "self" => self, "this" => self}
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
