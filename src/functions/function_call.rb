#!/usr/bin/env ruby


class FunctionCallStmt < BaseNode
  include FunctionUtils

  def initialize(name, args=[])
    @name, @args = name, args
    super()
  end

  def eval(scope)
    result = nil
    section = scope.get(@name)
    if section.class <= ClassNode or section.class <= ClassInstanceNode
      # reroute to constructor
      return ClassInstanceNode.new(section, @args, scope)
    else
      raise Error::MismatchedType.new(section, Hash) if section.class != Hash

      fn_def, param_values = FunctionUtils.find_fn(@name, @args, scope)

      # run in tmporary scope
      result = scope.exec_scope({:@scope_type => :fn_call}) {
        # inject parameter values into scope
        param_values.each {|name, val| 
          scope.set(name, val, true, false)
        }

        # evaluate statements in scope
        next fn_def[:stmts].eval(scope)
      }

      # typecheck return value and ensure it's a node
      result = EmptyNode.get_default if result == nil

      if !(TypeCheckSafety.type_conforms?(result, fn_def[:ret_type], scope))
        raise Error::MismatchedType.new(result, fn_def[:ret_type])
      end

      return result
    end
  end
end
