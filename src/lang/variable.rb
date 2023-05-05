#!/usr/bin/env ruby


# ✨ BUILT-IN VARIABLES
# ------------------------------------------------------------------------------

class DeclareVariableStmt < BaseNode
  attr_reader :type, :name, :value
  attr_accessor :const

  def initialize(type, name, value = nil, const = false)
    @type, @name, @value = type, name, value
    @const = const
    # Don't freeze, ConstStmt must be able to modify const flag.
  end

  def eval(scope)
    KeywordSafety.validate_keyword(@name)
    
    # get default object
    if @value == nil
      obj = TypeSafety.obj_from_typename(@type, scope)
    else
      obj = @value.eval(scope)
      
      if @type == MagicNode.type && obj.class != MagicNode
        obj = MagicNode.new(obj)  # wrap in magic
      elsif (obj == BaseNode and @type != obj.unwrap_all.type)
        raise Error::Magiika.new("requested container type `#{@type}' " + 
          "does not match data type `#{@object.type}'")
      end
    end
    
    obj = ConstNode.new(obj) if @const

    scope.add(@name, obj)
    
    return obj
  end
end


class AssignVariableStmt < BaseNode
  attr_reader :name

  def initialize(name, object = nil)
    @name, @object = name, object
    super()
  end

  def eval(scope)
    #puts "\n---"
    #puts "assigning #{@name} to #{@object}..."
    scope.scopes.each {
      |scope| 
      #puts "- #{scope[:@scope_type]}"
      if scope[@name] != nil && scope[@name].respond_to?(:value)
        #puts "  (value): #{scope[@name].value}"
      end
    }
    #puts "top scope:"
    #p scope.scopes[-1]
    #puts "---\n\n"

    var = scope.get(@name)
    raise Error::Magiika.new("undefined variable `#{@name}'.") if var == nil

    obj = @object.eval(scope) #obj = @object.unwrap
    if var.type == MagicNode.type
      obj = MagicNode.new(obj)  # wrap in magic
      scope.set(@name, obj, :replace)
    elsif var.type == obj.type || \
        (var.type == MagicNode.type && (var.magic_type == obj.type))
      scope.set(@name, obj, :replace)
    else
      raise Error::NoSuchCast.new(obj, var)
    end
    return obj
  end
end


class RetrieveVariableStmt < BaseNode
  attr_reader :name

  def initialize(name)
    @name = name
    super()
  end

  def eval(scope)
    return scope.get(@name)
  end

  def output(scope)
    return eval(scope)
  end
end


class ReassignVariableStmt < BaseNode
  attr_reader :name

  def initialize(name, object)
    @name, @object = name, object

    super()
  end

  def eval(scope)
    KeywordSafety.validate_keyword(@name)

    if !TypeSafety.valid_type?(@name, scope)
      raise Error::UnsupportedOperation.new("using `#{@name}' as a variable name.")
    end

    # get default object
    if @object == nil
      raise Error::UnsupportedOperation.new('redeclaration to nil.')
    else
      obj = MagicNode.new(@object.eval(scope))  # wrap in magic
    end

    scope.add(@name, obj, replace=True)
    
    return obj
  end

  def output(scope)
    obj = self.eval(scope)
    if obj.respond_to?(:output)
      return obj.output(scope)
    else
      return ''
    end
  end

  def bool_eval?(scope)
    self.eval(scope)
    return true
  end
end