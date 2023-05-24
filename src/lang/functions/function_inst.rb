#!/usr/bin/env ruby

class FunctionInstance < TypeNode
  attr_reader :params, :ret_attrs, :ret_type, :stmts

  def initialize(params, ret_attrs, ret_type, stmts)
    @params, @ret_attrs, @ret_type, @stmts = params, ret_attrs, ret_type, stmts
    self.freeze
  end

  def output
    return "(#{@params}) -> #{@ret_attrs} #{@ret_type}"
  end

  def self.type
    return 'fn'
  end
end
