#!/usr/bin/env ruby


class StmtsNode < BaseNode
  attr_reader :stmts
  
  def initialize(stmts)
    @stmts = stmts
    super()
  end

  def unwrap()
    return @stmts
  end

  def eval(scope)
    result = nil
    @stmts.each {
      |stmt|
      next if stmt == nil || stmt == :eol
      
      result = stmt.eval(scope)
      
      return result if stmt.class == ReturnStmtNode
    }
    return nil
  end
end


class CtrlStmtNode < BaseNode
end


class ReturnStmtNode < CtrlStmtNode
  attr_reader :value

  def initialize(value)
    @value = value
    super()
  end

  def eval(scope)
    return @value.eval(scope)
  end
end


class ContinueStmtNode < CtrlStmtNode
end


class BreakStmtNode < CtrlStmtNode
end


class BooleanInverterNode < BaseNode
  def initialize(value)
    @value = value
    super()
  end

  def eval(scope)
    return BoolNode.new(!(@value.bool_eval?(scope))).eval(scope)
  end

  def bool_eval?(scope)
    return BoolNode.new(!(@value.bool_eval?(scope))).bool_eval?(scope)
  end

  def output(scope)
    return eval.to_s
  end
end


class UnaryExpressionNode < BaseNode
  def initialize(op, obj)
    @op, @obj = op, obj
    super()
  end

  def eval(scope)
    obj = @obj.eval(scope).unwrap_all

    if obj.class.method_defined?(@op)
      return obj.public_send(@op)
    else
      raise Error::UnsupportedOperation.new(
        "`#{obj.type}' does not support `#{@op}'.")
    end
  end
end


class BinaryExpressionNode < BaseNode
  def initialize(l, op, r)
    @l, @op, @r = l, op, r
    super()
  end

  def eval(scope)
    l = @l.eval(scope).unwrap_all
    r = @r.eval(scope).unwrap_all
    if l.class.method_defined?(@op)
      return l.public_send(@op, r)
    else
      raise Error::UnsupportedOperation.new(
        "`#{@l.type}' does not support `#{@op}'.")
    end
  end
end


class PrintNode < BaseNode
  def initialize(value)
    @value = value
    super()
  end

  def eval(scope)
    result = @value.eval(scope)
    if result.respond_to?(:output)
      puts result.output(scope)
    elsif result != nil
      puts result
    else
      puts
    end
  end
end


class IfNode < BaseNode
  def initialize(cond, stmt, else_stmt = nil)
    @cond, @stmt, @else_stmt = cond, stmt, else_stmt
    super()
  end

  def eval(scope)
    if @cond.bool_eval?(scope)
      result = nil
      scope.exec_scope({:@scope_type => :control_if}) {
        result = @stmt.eval(scope)
      }
      return result 
    elsif @else_stmt
      @else_stmt.eval(scope)
    end
  end
end


class WhileNode < BaseNode
  def initialize(cond, stmts)
    @cond, @stmts = cond, stmts
    super()
  end

  def eval(scope)
    while @cond.bool_eval?(scope) do
      scope.exec_scope({:@scope_type => :control_while}) {
        @stmts.eval(scope)
      }
    end
  end
end
