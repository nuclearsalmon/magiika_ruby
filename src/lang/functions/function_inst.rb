#!/usr/bin/env ruby

class FunctionNode < TypeNode
  attr_reader :params, :ret_attrs, :ret_type, :stmts

  def initialize(params, ret_attrs, ret_type, stmts)
    @params, @ret_attrs, @ret_type, @stmts = params, ret_attrs, ret_type, stmts
    self.freeze
  end

  def output(scope)
    ret_attrs = @ret_attrs.to_s[1..-2]
    ret_type = @ret_type == nil ? 'empty' : @ret_type
    ret = "#{ret_attrs}#{' ' if @ret_attrs.length > 0}#{ret_type}"
    return "fn\n" \
      + "args: #{@params}\n" \
      + "return: <#{ret}>"
  end

  def self.type
    return 'fn'
  end
end
