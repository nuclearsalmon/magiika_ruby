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

      fn_def, fn_call_scope_slice = FunctionUtils.find_fn(@name, @args, scope)

      result = scope.exec_scope(fn_call_scope_slice) {
        puts "---\n"
        puts "calling #{@name}..."
        scope.scopes.each {
          |scope| 
          puts "- #{scope[:@scope_type]}"
          puts "  self: #{scope["self"].name}" if scope["self"] != nil
          puts "  this: #{scope["this"].name}" if scope["this"] != nil
          puts "  type: #{scope["type"].value}" if scope["type"] != nil
        }
        #puts "top scope:"
        #p scope.scopes[-1]
        puts "---\n"

        # evaluate statements in scope
        next fn_def[:stmts].eval(scope)
      }

      # typecheck return value and ensure it's a node
      result = EmptyNode.get_default if result == nil

      if !(TypeSafety.type_conforms?(result, fn_def[:ret_type], scope))
        raise Error::MismatchedType.new(result, fn_def[:ret_type])
      end

      return result
    end
  end
end
