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


class ConditionNode < WrapNode
  def initialize(l, op, r)
    @l, @op, @r = l, op, r
  end

	def unwrap
		l, r = @l.unwrap, @r.unwrap
		case @op
		when "and", "&&"
			return BoolNode.new(l.bool_value && r.bool_value)
		when "or", "||"
			return BoolNode.new(l.bool_value || r.bool_value)
		else
			raise "unsupported operation: " + 
				"`#{get_expanded_type(l)} #{@op} #{get_expanded_type(r)}'."
		end
	end

	def output
		return eval
	end

	def eval
		return unwrap.eval
	end

	def bool_value
		return eval
	end
end


class ExpressionNode < WrapNode
	def initialize(l, op, r)
		@l, @op, @r = l, op, r
	end

	def unwrap
		l = @l.unwrap
		r = @r.unwrap

		if l.type == "empty" then
			value = instance_eval("#{@op}#{r.eval}")
			return get_obj_from_type(r.type).new(value)
		end

		case @op
		when "+", "-"
			if l.type == r.type then
				value = instance_eval("#{l.eval}#{@op}#{r.eval}")
				
				if l.type == "magic" then
					value = get_obj_from_type(l.magic_type).new(value)
				end

				return get_obj_from_type(r.type).new(value)
			end
			raise	"unsupported operation, mismatched types: `#{exp_l_type}' #{@op} `#{exp_r_type}'"
		else
			exp_l_type = get_expanded_type(l)
			exp_r_type = get_expanded_type(r)
			raise	"unsupported operation: `#{exp_l_type}' #{@op} `#{exp_r_type}'"
		end
	end

	def output
		return eval
	end

	def eval
		return unwrap.eval
	end
end
