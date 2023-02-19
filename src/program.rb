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

		if l.type == "empty" then
			value = instance_eval("#{@op}#{r.eval}")
			return type_to_node_class(r.type).new(value)
		end

		case @op
		when "+", "-"
			if l.type == r.type then
				value = instance_eval("#{l.eval}#{@op}#{r.eval}")
				
				if l.type == "magic" then
					value = type_to_node_class(l.unwrap.type).new(value)
				end

				return type_to_node_class(r.type).new(value)
			end
			raise	"unsupported operation, mismatched types: `#{exp_l_type}' #{@op} `#{exp_r_type}'"
		else
			raise	"unsupported operation: `#{l.expanded_type}' #{@op} `#{r.expanded_type}'"
		end
	end

	def output
		return eval
	end

	def eval
		return unwrap.eval
	end
end
