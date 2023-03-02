#!/usr/bin/env ruby


# ✨ BUILT-IN VARIABLES
# ------------------------------------------------------------------------------

class DeclareVariable < BaseNode
  attr_reader :type, :name

  def initialize(type, name, object = nil, scope_handler)
    @type, @name, @object = type, name, object
    @scope_handler = scope_handler

    if BUILT_IN_TYPES.keys.include?(@name) then
      raise MagiikaUnsupportedOperationError.new(
        "using `#{@name}' as a variable name.")
    end

    if @type != MagicNode.type and
        (@object != nil and @type != @object.unwrap.type) then
      raise MagiikaError.new("requested container type `#{@type}' " + 
        "does not match data type `#{@object.type}'")
    end
  end

  def eval
    # get default object
    if @object == nil then
      obj = type_to_node_class(@type).get_default
    else
      obj = @object.eval
      
      if @type == MagicNode.type then
        obj = MagicNode.new(obj)  # wrap in magic
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
    raise MagiikaError.new("undefined variable `#{@name}'.") if var == nil

    obj = @object.eval #obj = @object.unwrap
    if var.type == MagicNode.type then
      obj = MagicNode.new(obj)  # wrap in magic
      @scope_handler.set_var(@name, obj)
    elsif var.type == obj.type || 
      (var.type == MagicNode.type && (var.magic_type == obj.type)) then
      @scope_handler.set_var(@name, obj)
    else
      raise MagiikaNoSuchCastError.new(obj, var)
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
    return unwrap.eval
  end

  def output
    return unwrap
  end

  def bool_eval?
    return unwrap.bool_eval?
  end

  def unwrap
    return @scope_handler.get_var(@name)
  end
end


class RedeclareVariable < BaseNode
  attr_reader :name

  def initialize(name, object, scope_handler)
    @name, @object = name, object
    @scope_handler = scope_handler

    if BUILT_IN_TYPES.keys.include?(@name) then
      raise MagiikaUnsupportedOperationError.new(
        "using `#{@name}' as a variable name.")
    end
  end

  def unwrap
    # get default object
    if @object == nil then
      raise MagiikaUnsupportedOperationError.new(
        "redeclaration to nil.")
    else
      obj = MagicNode.new(@object.eval)  # wrap in magic
    end

    @scope_handler.relaxed_add_var(@name, obj)
    
    return obj
  end

  def output
    return unwrap.output
  end

  def bool_eval?
    return unwrap.bool_eval?
  end

  def eval
    return unwrap.eval
  end
end