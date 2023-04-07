#!/usr/bin/env ruby


class AbstractFunctionDefStmt < BaseNode
  def initialize(name, params, ret_type)
    @name, @params, @ret_type = name, params, ret_type
    super()
  end

  def eval(scope)
    fn_def = {
      :@type => :abs_fn_def, 
      :params => @params, 
      :ret_type => @ret_type,
      :stmts => nil
    }
    fn_key = FunctionUtils.get_fn_key(FunctionUtils.types_from_params(@params))

    scope.section_add(@name, fn_key, fn_def)
  end
end


class FunctionDefStmt < BaseNode
  def initialize(name, params, ret_type, stmts)
    @name, @params, @ret_type, @stmts = name, params, ret_type, stmts
    super()
  end

  def eval(scope)
    fn_def = {
      :@type => :fn_def, 
      :params => @params, 
      :ret_type => @ret_type,
      :stmts => @stmts
    }
    fn_key = FunctionUtils.get_fn_key(FunctionUtils.types_from_params(@params))
    
    scope.section_add(@name, fn_key, fn_def)
  end
end
