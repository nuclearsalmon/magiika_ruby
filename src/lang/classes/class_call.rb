#!/usr/bin/env ruby


class MemberAccessStmt < BaseNode
  attr_reader :source, :action
  def initialize(source, action)
    @source, @action = source, action

    super()
  end

  def unwrap_eval(scope)
    src_obj = @source.eval(scope).unwrap_all()
    
    action = @action
    while action.class <= MemberAccessStmt
      if !src_obj.respond_to?(:run)
        raise Error::UnsupportedOperation.new(
          "`#{src_obj.type}' does not support entering its scope.")
      end

      src_obj = src_obj.run(action.source, scope)
      action = action.action
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
      action = action.action
    end

    if action.class <= RetrieveVariableStmt
      var_name = action.name
      # important, otherwise we end up with uneval'd assignments
      value    = @value.eval(scope)
      
      src_obj.set(var_name, value, scope)
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
