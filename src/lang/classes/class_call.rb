#!/usr/bin/env ruby


class MemberAccessStmt < TypeNode
  attr_reader :source, :action
  def initialize(source, action)
    @source, @action = source, action

    super()
  end

  def unwrap_eval_old(scope)
    obj = @source.eval(scope).unwrap_all()
    
    if !obj.respond_to?(:run)
      raise Error::UnsupportedOperation.new(
        "`#{obj.type}'does not respond to member calls.")
    end
    
    return obj.run(@action, scope)
  end

  def unwrap_eval(scope)
    src_obj = @source.eval(scope).unwrap_all()
    
    if !src_obj.respond_to?(:run)
      raise Error::UnsupportedOperation.new(
        "`#{src_obj.type}'does not respond to member calls.")
    end

    result = nil
    if @action.class <= MemberAccessStmt
      puts "resolving obj ..."
      action = @action
      while action.class <= MemberAccessStmt
        src_obj = src_obj.run(action, scope)
        action = action.action
      end

      result = src_obj
    else
      puts "running obj ..."
      result = src_obj.run(@action, scope)
    end

    puts "final result:"
    p result
    return result
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
