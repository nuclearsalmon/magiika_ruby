#!/usr/bin/env ruby


# ✨ BUILT-IN VARIABLES
# ------------------------------------------------------------------------------

class DeclareVariableStmt < BaseNode
  attr_reader :attribs, :type, :name, :value

  def initialize(attribs, type, name, value=nil)
    @attribs, @type, @name, @value = attribs, type, name, value
    freeze
  end

  def eval(scope)
    KeywordSafety.verify_keyword_not_restricted(@name)

    # evaluate type
    type = @type
    attribs = @attribs
    if type == nil
      # inject magic attribute if missing
      # FIXME: modifying instance variable
      attribs << :magic if !attribs.include?(:magic)
    else
      type = @type.eval(scope)
    end
    
    # get default object
    obj = @value
    if obj == nil
      if type == nil
        # no type specified, force magic
        if !@attribs.include?(:empty)
          raise Error::Magiika.new(\
            "`#{@name}' is not allowed to be empty, yet is missing a value.")
        end
        
        obj = EmptyNode.get_default()
      else
        if type.respond_to?(:get_default)
          obj = type.get_default()
        else
          if !@attribs.include?(:empty)
            raise Error::Magiika.new("No default state exists for Type `#{type}'.")
          end

          obj = EmptyNode.get_default()
        end
      end
    else
      obj = @value.eval(scope)
    end

    obj = obj.unwrap_only_class(MetaNode)
    meta = MetaNode.new(attribs, obj, type)
    scope.add(@name, meta)
    return meta
  end
end


class AssignVariableStmt < BaseNode
  attr_reader :name

  def initialize(name, obj)
    @name, @obj = name, obj
    freeze
  end

  def eval(scope)
    meta = scope.get(@name)
    obj = @obj.eval(scope).unwrap_only_class(MetaNode)
    meta.set_node(obj)

    return obj
  end
end


class ReassignVariableStmt < BaseNode
  attr_reader :name

  def initialize(name, obj)
    @name, @obj = name, obj
    freeze
  end

  def eval(scope)
    KeywordSafety.verify_keyword_not_restricted(@name)

    obj = @obj.eval(scope)
    meta = scope.get(@name)
    meta.set_node(obj)
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
    return self.eval(scope).bool_eval?(scope)
  end
end


class RetrieveVariableStmt < BaseNode
  attr_reader :name

  def initialize(name)
    @name = name
    freeze
  end

  def eval(scope)
    return scope.get(@name)
  end

  def bool_eval?(scope)
    return self.eval(scope).bool_eval?(scope)
  end

  def output(scope)
    return eval(scope)
  end
end


class RetrieveTypeStmt < BaseNode
  attr_reader :name

  def initialize(access)
    @access = access
    freeze
  end

  def eval(scope)
    obj = @access.eval(scope).unwrap_only_class(MetaNode)

    # Verify valid type
    TypeSafety.verify_is_a_type(obj)

    return obj
  end

  def bool_eval?(scope)
    return self.eval(scope).bool_eval?(scope)
  end

  def output(scope)
    return eval(scope)
  end
end


class MemberAccessStmt < BaseNode
  attr_reader :source, :action
  def initialize(source, action)
    @source, @action = source, action

    super()
  end

  def eval(scope)
    src_obj = @source.eval(scope).unwrap_all()
    action = @action

    while action.class <= MemberAccessStmt
      if !src_obj.respond_to?(:run)
        raise Error::UnsupportedOperation.new(
          "`#{src_obj.type}' does not support entering its scope.")
      end

      src_obj = src_obj.run(action.source, scope)
      src_obj = src_obj.unwrap_only_class(MetaNode)
      action = action.action
    end

    if (src_obj.class <= ClassNode || src_obj.class <= ClassInstanceNode)
      return src_obj.run(action, scope)
    else
      raise Error::MismatchedType.new(src_obj, [ClassNode, ClassInstanceNode])
    end
  end

  def bool_eval?(scope)
    return self.eval(scope).bool_eval?(scope)
  end
end


class MemberAssignStmt < BaseNode
  def initialize(access, value)
    @access, @value = access, value

    super()
  end

  def unwrap_eval(scope)
    if !(@access.class <= MemberAccessStmt)
      raise Error::Magiika.new(
        "@action should always be a MemberAccessStmt: #{@action.class}")
    end
    
    src_obj = @access.source.eval(scope).unwrap_all()
    action = @access.action
    while action.class <= MemberAccessStmt
      if !src_obj.respond_to?(:run)
        raise Error::UnsupportedOperation.new(
          "`#{src_obj.type}' does not support entering its scope.")
      end

      src_obj = src_obj.run(action.source, scope)
      src_obj = src_obj.unwrap_only_class(MetaNode)
      action = action.action
    end

    if action.class <= RetrieveVariableStmt
      var_name = action.name
      # important, otherwise we end u#p with uneval'd assignments
      value    = @value.eval(scope)

      if (src_obj.class <= ClassNode || src_obj.class <= ClassInstanceNode)
        src_obj.run(AssignVariableStmt.new(var_name, value), scope)
      else
        raise Error::MismatchedType.new(src_obj, [ClassNode, ClassInstanceNode])
      end
    else
      raise Error::Magiika.new(
        "Action #{action.class} cannot be used for variable assignment.")
    end

    return src_obj.run(action, scope)
  end

  def eval(scope)
    return unwrap_eval(scope).eval(scope)
  end

  def bool_eval?(scope)
    return unwrap_eval(scope).bool_eval?(scope)
  end

  def output(scope)
    return unwrap_eval(scope).output(scope)
  end
end
