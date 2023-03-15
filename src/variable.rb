#!/usr/bin/env ruby


# ✨ BUILT-IN VARIABLES
# ------------------------------------------------------------------------------

class DeclareVariable < BaseNode
  attr_reader :type, :name

  def initialize(type, name, object = nil, scope_handler)
    @type, @name, @object = type, name, object
    @scope_handler = scope_handler

    if TypeUtils.valid_type?(@name)
      raise Error::UnsupportedOperation.new(
        "using `#{@name}' as a variable name.")
    end
  end

  def eval
    # get default object
    if @object == nil
      obj = TypeUtils.type_to_node_cls(@type).get_default
    else
      obj = @object.eval
      
      if @type == MagicNode.type && obj.class != MagicNode
        obj = MagicNode.new(obj)  # wrap in magic
      elsif (obj == BaseNode and @type != obj.unwrap_all.type)
        raise Error::Magiika.new("requested container type `#{@type}' " + 
          "does not match data type `#{@object.type}'")
      end
    end
    
    @scope_handler.add_var(@name, obj)
    
    return obj
  end
end


class AssignVariable < BaseNode
  attr_reader :name

  def initialize(name, object = nil, scope_handler)
    @name, @object = name, object
    @scope_handler = scope_handler
  end

  def eval
    var = @scope_handler.get_var(@name)
    raise Error::Magiika.new("undefined variable `#{@name}'.") if var == nil

    obj = @object.eval #obj = @object.unwrap
    if var.type == MagicNode.type
      obj = MagicNode.new(obj)  # wrap in magic
      @scope_handler.set_var(@name, obj)
    elsif var.type == obj.type || 
      (var.type == MagicNode.type && (var.magic_type == obj.type))
      @scope_handler.set_var(@name, obj)
    else
      raise Error::NoSuchCast.new(obj, var)
    end
    return obj
  end
end


class RetrieveVariable < BaseNode
  attr_reader :name

  def initialize(name, scope_handler)
    @name, @scope_handler = name, scope_handler
  end

  def eval
    return @scope_handler.get_var(@name)
  end

  def output
    return @scope_handler.get_var(@name)
  end
end


class RedeclareVariable < BaseNode
  attr_reader :name

  def initialize(name, object, scope_handler)
    @name, @object = name, object
    @scope_handler = scope_handler

    if TypeUtils.valid_type?(@name)
      raise Error::UnsupportedOperation.new(
        "using `#{@name}' as a variable name.")
    end
  end

  def eval_base
    # get default object
    if @object == nil
      raise Error::UnsupportedOperation.new(
        "redeclaration to nil.")
    else
      obj = MagicNode.new(@object.eval)  # wrap in magic
    end

    @scope_handler.relaxed_add_var(@name, obj)
    
    return obj
  end

  def output
    return eval_base.output
  end

  def bool_eval?
    return eval_base.bool_eval?
  end

  def eval
    return eval_base.eval
  end
end