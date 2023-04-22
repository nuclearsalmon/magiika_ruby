#!/usr/bin/env ruby


# ✨ BUILT-IN VARIABLES
# ------------------------------------------------------------------------------

class DeclareVariable < BaseNode
  attr_reader :type, :name

  def initialize(type, name, object = nil)
    @type, @name, @object = type, name, object

    super()
  end

  def eval(scope)
    KeywordSafety.validate_keyword(@name)
    
    # get default object
    if @object == nil
      obj = TypeSafety.obj_from_typename(@type, scope)
    else
      obj = @object.eval(scope)
      
      if @type == MagicNode.type && obj.class != MagicNode
        obj = MagicNode.new(obj)  # wrap in magic
      elsif (obj == BaseNode and @type != obj.unwrap_all.type)
        raise Error::Magiika.new("requested container type `#{@type}' " + 
          "does not match data type `#{@object.type}'")
      end
    end
    
    scope.add(@name, obj)
    
    return obj
  end
end


class AssignVariable < BaseNode
  attr_reader :name

  def initialize(name, object = nil)
    @name, @object = name, object
    super()
  end

  def eval(scope)
    puts "\n---"
    puts "assigning #{@name} to #{@object}..."
    scope.scopes.each {
      |scope| 
      puts "- #{scope[:@scope_type]}"
      puts "  (value): #{scope[@name].value}" if scope[@name] != nil && scope[@name].respond_to?(:value)
    }
    #puts "top scope:"
    #p scope.scopes[-1]
    puts "---\n\n"

    var = scope.get(@name)
    raise Error::Magiika.new("undefined variable `#{@name}'.") if var == nil

    obj = @object.eval(scope) #obj = @object.unwrap
    if var.type == MagicNode.type
      obj = MagicNode.new(obj)  # wrap in magic
      scope.set(@name, obj, :replace)
    elsif var.type == obj.type || 
      (var.type == MagicNode.type && (var.magic_type == obj.type))
      scope.set(@name, obj, :replace)
    else
      raise Error::NoSuchCast.new(obj, var)
    end
    return obj
  end
end


class RetrieveVariable < BaseNode
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


class RedeclareVariable < BaseNode
  attr_reader :name

  def initialize(name, object)
    @name, @object = name, object

    super()
  end

  def eval_base(scope)
    KeywordSafety.validate_keyword(@name)

    if !TypeSafety.valid_type?(@name, scope)
      raise Error::UnsupportedOperation.new(
        "using `#{@name}' as a variable name.")
    end

    # get default object
    if @object == nil
      raise Error::UnsupportedOperation.new(
        "redeclaration to nil.")
    else
      obj = MagicNode.new(@object.eval(scope))  # wrap in magic
    end

    scope.add(@name, obj, replace=True)
    
    return obj
  end

  def output(scope)
    return eval_base.output(scope)
  end

  def bool_eval?(scope)
    return eval_base.bool_eval?(scope)
  end

  def eval(scope)
    return eval_base.eval(scope)
  end
end