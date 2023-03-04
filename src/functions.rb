#!/usr/bin/env ruby

module FunctionUtils
  def get_param_key
    if @params == nil || @params.length == 0 then
      return ""
    end

    key = ""
    @params.each {|param| key += (param[1] + " ")}  # type
    return key[0..-2]
  end
end


class FunctionDefinition < BaseNode
  include FunctionUtils

  def initialize(name, params, ret_type, stmts, scope_handler)
    @name, @params, @ret_type, @stmts = name, params, ret_type, stmts
    @scope_handler = scope_handler
  end

  def eval()
    definition = [@params, @ret_type, @stmts]
    @scope_handler.add_func(@name, get_param_key(), definition)
  end
end


class FunctionCall < BaseNode
  include FunctionUtils

  def initialize(name, args=nil, scope_handler)
    @name, @args = name, args
    @scope_handler = scope_handler
  end

  def unwrap
    definition = @scope_handler.get_func(name, get_param_key)
    stmts = definition[2]

    result = nil
    @scope_handler.temp_scope {
      result = stmts.eval
    }

    if result == nil
      return EmptyNode.get_default
    else
      return result
    end
  end

  def eval
    return unwrap.eval
  end

  def bool_eval?
    return unwrap.bool_eval?
  end
end
