#!/usr/bin/env ruby

module FunctionUtils
  def get_fn_key(src)
    return "" if @src == nil || @src.length == 0

    key = ""
    @src.each {|e| key += (e[1] + " ")}  # [1] <- type
    return key[0..-2]
  end
  module_function :get_fn_key

  def get_fn_sig(name, params, ret_type)
    return "#{name}(#{params}) -> #{ret_type}"
  end
  module_function :get_fn_sig
end


class FunctionDefinition < BaseNode
  include FunctionUtils

  def initialize(name, params, ret_type, stmts, scope_handler)
    @name, @params, @ret_type, @stmts = name, params, ret_type, stmts
    @scope_handler = scope_handler
  end

  def eval()
    fn_def = [@params, @ret_type, @stmts]
    @scope_handler.add_func(@name, get_fn_key(fn_def), fn_def)
  end
end


class FunctionCall < BaseNode
  include FunctionUtils

  def initialize(name, args=nil, scope_handler)
    @name, @args = name, args
    @scope_handler = scope_handler
  end

  def unwrap
    return @scope_handler.temp_fn_call_scope(@name, @args)
  end

  def eval
    return unwrap.eval
  end

  def bool_eval?
    return unwrap.bool_eval?
  end
end
