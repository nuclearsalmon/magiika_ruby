#!/usr/bin/env ruby


class FunctionDefStmt < BaseNode
  attr_reader :attribs, :name, :params, :ret_attribs, :ret_type, :stmts

  def initialize(attribs, name, params, ret_attribs, ret_type, stmts)
    @name = name
    @attribs = attribs
    @params = params
    @ret_attribs = ret_attribs
    @ret_type = ret_type
    @stmts = stmts
    
    freeze
  end

  def eval(scope)
    # Validate abstractness
    if @attribs.include?(:abst) && @stmts.length != 0
      raise Error::Magiika.new('Abstract functions cannot contain statements.')
    end

    # Validate return attributes
    MetaNode.new(@ret_attribs, nil, nil, true)
    
    # Evaluate return type
    ret_type = @ret_type
    if ret_type != nil
      ret_type = @ret_type.eval(scope)
      TypeSafety.verify_is_a_type(ret_type)
    end

    params = @params.clone
    params.each {
      |param|
      param[:type] = param[:type].eval(scope) if param[:type].class != NilClass
    }

    fn_key = FunctionUtils.get_fn_key(FunctionUtils.types_from_params(@params))
    fn_def = FunctionInstance.new(params, @ret_attribs, ret_type, @stmts)
    meta = MetaNode.new(@attribs, fn_def, FunctionInstance)
    
    scope.section_set(@name, fn_key, meta, :push)
  end
end
