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


class ConditionNode < BaseNode
  def initialize(l, op, r)
    @l, @op, @r = l, op, r
  end

  def unwrap
    l, r = @l.unwrap, @r.unwrap
    case @op
    when "and", "&&"
      return BoolNode.new(l.bool_eval? && r.bool_eval?)
    when "or", "||"
      return BoolNode.new(l.bool_eval? || r.bool_eval?)
    else
      raise MagiikaUnsupportedOperationError.new(
        "`#{get_expanded_type(l)} #{@op} #{get_expanded_type(r)}'.")
    end
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


class ExpressionNode < BaseNode
  def initialize(l, op, r)
    @l, @op, @r = l, op, r
  end

  def unwrap
    l = @l.unwrap
    r = @r.unwrap

    if l == EmptyNode.get_default then
      if !r.class.method_defined?(@op) then
        raise	MagiikaUnsupportedOperationError.new("`#{@op}' `#{r.type}'.")
      end

      return r.public_send(@op)
    elsif r == EmptyNode.get_default then
      raise MagiikaUnsupportedOperationError.new(
        "right-hand value must not be nil.")
    else
      if !l.class.method_defined?(@op) then
        raise	MagiikaUnsupportedOperationError.new(
          "`#{l.type}' `#{@op}' `#{r.type}'")
      end

      if l.type != r.type then
        raise	MagiikaUnsupportedOperationError.new(
          "mismatched types: `#{l.type}' #{@op} `#{r.type}'")
      end

      return l.public_send(@op, r)
    end
  end

  def output
    return eval
  end

  def eval
    return unwrap.eval
  end
end


class IfNode < BaseNode
  def initialize(cond, stmt, scope_handler, else_stmt = nil)
    @cond, @stmt, @else_stmt = cond, stmt, else_stmt
    @scope_handler = scope_handler
  end

  def eval
    if @cond.bool_eval? then
      @scope_handler.new_scope
      result = @stmt.eval
      @scope_handler.discard_scope
      return result 
    elsif @else_stmt
      @else_stmt.eval
    end
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
