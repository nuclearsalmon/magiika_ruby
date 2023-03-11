#!/usr/bin/env ruby


class StmtsNode < BaseNode
  def initialize(stmt, stmts)
    @stmt, @stmts = stmt, stmts
  end

  def eval
    if @stmt == :eol
      out = nil
    else 
      out = @stmt.eval
    end

    if @stmts.class == StmtsNode 
      @stmts.eval
    end
    return out
  end

  def quiet_eval
    @stmt.eval if @stmt != :eol
    @stmts.eval if @stmts.class == StmtsNode
  end
end


class BooleanInverterNode < BaseNode
  def initialize(value)
    @value = value
  end

  def eval
    return BoolNode.new(!(@value.bool_eval?)).eval
  end

  def bool_eval?
    return BoolNode.new(!(@value.bool_eval?)).bool_eval?
  end

  def output
    return eval.to_s
  end
end


class UnaryExpressionNode < BaseNode
  def initialize(op, obj)
    @op, @obj = op, obj
  end

  def eval
    obj = @obj.eval

    if obj.class.method_defined?(@op)
      return obj.public_send(@op)
    else
      raise MagiikaUnsupportedOperationError.new(
        "`#{obj.type}' does not support `#{@op}'.")
    end
  end
end


class BinaryExpressionNode < BaseNode
  def initialize(l, op, r)
    @l, @op, @r = l, op, r
  end

  def eval
    l = @l.eval
    r = @r.eval
    if l.class.method_defined?(@op)
      return l.public_send(@op, r)
    else
      raise MagiikaUnsupportedOperationError.new(
        "`#{@l.type}' does not support `#{@op}'.")
    end
  end
end


class PrintNode < ContainerTypeNode
  def eval
    value = @value.unwrap_all
    result = value.eval
    if result.respond_to?(:output)
      puts result.output
    elsif result != nil
      puts result
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
    if @cond.bool_eval?
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
