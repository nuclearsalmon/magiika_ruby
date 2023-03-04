#!/usr/bin/env ruby


class StmtsNode < BaseNode
  def initialize(stmt, stmts)
    @stmt, @stmts = stmt, stmts
  end

  def eval
    if @stmt == :eol
      out = nil
    else 
      if @stmt.class.method_defined?(:output)
        out = @stmt.output
      else
        @stmt.eval
        out = nil
      end
    end

    if @stmts.class == StmtsNode 
       @stmts.eval 
    else
      return out
    end
  end
end


class BooleanInverterNode < BaseNode
  def initialize(value)
    @value = value
  end

  def unwrap
    return BoolNode.new(!(@value.bool_eval?))
  end

  def output
    return eval
  end

  def eval
    return unwrap.eval
  end

  def bool_eval?
    return eval
  end
end


class UnaryExpressionNode < BaseNode
  def initialize(op, obj)
    @op, @obj = op, obj
  end

  def unwrap
    obj = @obj.unwrap_all

    if obj.class.method_defined?(@op) then
      return obj.public_send(@op)
    else
      raise MagiikaUnsupportedOperationError.new(
        "`#{obj.type}' does not support `#{@op}'.")
    end
  end

  def eval
    return unwrap.eval
  end

  def output
    return eval
  end
end


class BinaryExpressionNode < BaseNode
  def initialize(l, op, r)
    @l, @op, @r = l, op, r
  end

  def unwrap
    l = @l.unwrap
    r = @r.unwrap

    if l.class.method_defined?(@op) then
      return l.public_send(@op, r)
    else
      raise MagiikaUnsupportedOperationError.new(
        "`#{l.type}' does not support `#{@op}'.")
    end
  end

  def eval
    return unwrap.eval
  end

  def bool_eval?
    return unwrap.bool_eval?  # fixme optimize
  end

  def output
    return eval
  end
end


class PrintNode < ContainerTypeNode
  def eval
    value = @value.unwrap_all
    if value.respond_to?(:value) then
      puts value.value
    elsif value.respond_to?(:output) then
      puts value.output
    else
      puts
    end
  end
end


class IfNode < BaseNode
  def initialize(cond, stmt, scope_handler, else_stmt = nil)
    @cond, @stmt, @else_stmt = cond, stmt, else_stmt
    @scope_handler = scope_handler
  end

  def eval
    if @cond.bool_eval? then
      result = nil
      @scope_handler.temp_scope {
        result = @stmt.eval
      }
      return result 
    elsif @else_stmt
      @else_stmt.eval
    end
  end
end


class WhileNode < BaseNode
  def initialize(cond, stmts, scope_handler)
    @cond, @stmts = cond, stmts
    @scope_handler = scope_handler
  end

  def eval
    while @cond.bool_eval? do
      @scope_handler.temp_scope {
        @stmts.eval
      }
    end
  end
end
