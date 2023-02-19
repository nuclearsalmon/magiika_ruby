#!/usr/bin/env ruby


# Note: Defining a BaseNode and WrapNode is technically
# unnecessary thanks to duck typing, but it makes reading
# the relationships between different nodes easier.

class BaseNode
	def eval
		raise MagiikaNotImplementedError.new
	end
end


class WrapNode < BaseNode
	def unwrap
		return self
	end

	def eval
		return unwrap.eval
	end
end


class EmptyNode < WrapNode
	def self.type
		return "empty"
	end

	def type
		return self.class.type
	end

	def output
		return "empty"
	end

	def eval
		return "empty"
	end

	def unwrap
		return self
	end

	def bool_value
		return false
	end

	def self.get_default_instance
		return EmptyNode.new
	end
end


class DataNode < EmptyNode
	attr_accessor :value

	def initialize(value)
		@value = value
	end

	def self.type
		raise MagiikaNotImplementedError.new
	end

	def output
		return @value
	end

	def eval
		return @value
	end

	def bool_value
		return true
	end

	def self.get_default_value
		raise MagiikaNotImplementedError.new
	end

	def self.get_default_instance
		raise MagiikaNotImplementedError.new
	end

	def cast(from, value)
		raise MagiikaNotImplementedError.new
	end
end


class IntNode < DataNode
	def initialize(value)
		if value.class != Integer then
			raise MagiikaInvalidTypeError.new(value, self.type)
		end
		super(value)
	end

	def self.type
		return "int"
	end

	def bool_value
		return @value != 0
	end

	def self.get_default_value
		return 0
	end

	def self.get_default_instance
		return IntNode.new(self.get_default_value)
	end
end


class FltNode < DataNode
	def initialize(value)
		if value.class != Integer && value.class != Float then
			raise MagiikaInvalidTypeError.new(value, self.type)
		end
		super(value)
	end

	def self.type
		return "flt"
	end

	def bool_value
		return @value != 0.0
	end
	
	def self.get_default_value
		return 0.0
	end

	def self.get_default_instance
		return FltNode.new(self.get_default_value)
	end
end


class BoolNode < DataNode
	def initialize(value)
		if value.class != TrueClass and value.class != FalseClass then
			raise MagiikaInvalidTypeError.new(value, self.type)
		end
		super(value)
	end

	def self.type
		return "bool"
	end

	def bool_value
		return @value
	end

	def self.get_default_value
		return false
	end

	def self.get_default_instance
		return BoolNode.new(self.get_default_value)
	end
end


class MagicNode < DataNode
	def initialize(value)
		if value == nil then
			value = EmptyNode.new
		end
		if value != nil then
			value = value.unwrap
			if !(value.class == EmptyNode || value.class < DataNode) then
				raise MagiikaError.new("invalid type, `#{value}' is not empty or a built in type.")
			end
		end
		super(value)
	end

	def self.type
		return "magic"
	end

	def magic_type
		return EmptyNode.type if @value == nil  # this should never happen
		return @value.type
	end

	def output
		return nil if @value == nil  # this should never happen
		return @value.output
	end

	def bool_value
		return nil if @value == nil  # this should never happen
		return @value.bool_value
	end

	def self.get_default_value
		return EmptyNode.new
	end

	def self.get_default_instance
		return MagicNode.new(self.get_default_value)
	end

	def eval
		return nil if value == nil
		return @value.eval
	end
end


BUILT_IN_TYPES = {
	"empty" => EmptyNode,
	"magic" => MagicNode,
	"bool" => BoolNode, 
	"int" => IntNode, 
	"flt" => FltNode}


def get_obj_from_type(type)
	return BUILT_IN_TYPES[type]
end


def get_expanded_type(node)
	return node.type == "magic" ? node.type + "(#{node.magic_type})" : node.type
end
