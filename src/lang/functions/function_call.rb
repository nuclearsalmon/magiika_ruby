#!/usr/bin/env ruby


class FunctionCallStmt < BaseNode
  include FunctionUtils

  def initialize(name, args=[])
    @name, @args = name, args

    super()
  end

  def eval(scope)
    result = nil
    section = scope.section_get(@name)
    if section.class != Hash
      section = section.unwrap() if section.class <= MetaNode
      
      if section.class <= ClassNode
        # reroute to constructor
        return ClassInstanceNode.new(section, @args, scope)
      else
        raise Error::MismatchedType.new(section, [ClassNode, FunctionNode])
      end
    else
      fn_def_meta, fn_call_scope_slice = FunctionUtils.find_fn(@name, @args, scope)

      if fn_def_meta.abstract
        raise Error::Magiika.new('Abstract functions cannot be evaluated.')
      end

      fn_def = fn_def_meta.unwrap

      result = scope.exec_scope(fn_call_scope_slice) {
        # evaluate statements in scope
        next fn_def.stmts.eval(scope)
      }
  
      # typecheck return value and ensure it's a node
      result = EmptyNode.get_default if result == nil
  
      if !(TypeSafety.obj_is_type?(result, fn_def.ret_type))
        raise Error::MismatchedType.new(result, fn_def.ret_type)
      end
  
      result = result.unwrap_only_class(MetaNode)
      meta = MetaNode.new(fn_def.ret_attrs, result, fn_def.ret_type)
      return meta
    end
  end
end
