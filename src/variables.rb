#!/usr/bin/env ruby


# ✨ BUILT-IN VARIABLES
# ------------------------------------------------------------------------------

class DeclareVariable < BaseNode
	attr_reader :type, :name

	def initialize(type, name, object = nil, scope_handler)
		@type, @name, @object = type, name, object
		@scope_handler = scope_handler

		if BUILT_IN_TYPES.keys.include?(@name) then
			raise "using `#{@name}' as a variable name is not allowed."
		end

		if @type != "magic" and 
				(@object != nil and @type != @object.unwrap.type) then
			raise "requested container type `#{@type}' does not match data type `#{@object.type}'"
		end
	end

	def default_object
		def_obj = get_obj_from_type(@type)
		raise "no default object exists for type `#{@type}'." if def_obj == nil
		return def_obj
	end

	def eval
		# get default object
		if @object == nil then
			obj = default_object.get_default_instance
		else
			obj = @object
		end

		# wrap in magic if requested
		if @type == "magic" then
			obj = MagicNode.new(obj)
		end
		
		@scope_handler.add_var(@name, obj)
		
		return obj
	end
end


class AssignVariable < BaseNode
	attr_reader :name

	def initialize(name, object = nil, scope_handler)
		@name, @object = name, object
		@scope_handler = scope_handler
	end

	def eval
		var = @scope_handler.get_var(@name)
		raise "undefined variable `#{@name}'." if var == nil

		# handle magic
		obj = @object.unwrap
		if var.type == "magic" then
			obj = MagicNode.new(obj)
			@scope_handler.set_var(@name, obj)
		elsif var.type == obj.type || 
			(var.type == "magic" && (var.magic_type == obj.type)) then
			@scope_handler.set_var(@name, obj)
		else
			exp_obj_type = get_expanded_type(obj)
			exp_var_type = get_expanded_type(var)
			raise "mismatched types: `#{exp_var_type}' from `#{exp_obj_type}'."
		end
		return obj
	end
end


class RetrieveVariable < WrapNode
	attr_reader :name

	def initialize(name, scope_handler)
		@name, @scope_handler = name, scope_handler
	end

	def unwrap
		return @scope_handler.get_var(@name)
	end

	def output
		return unwrap.output
	end

	def bool_value
		return unwrap.bool_value
	end

	def eval
		return unwrap.eval
	end
end


class RedeclareVariable < WrapNode
	attr_reader :name

	def initialize(name, object, scope_handler)
		@name, @object = name, object
		@scope_handler = scope_handler

		if BUILT_IN_TYPES.keys.include?(@name) then
			raise "using `#{@name}' as a variable name is not allowed."
		end
	end

	def unwrap
		# get default object
		if @object == nil then
			raise "Redeclaration to nil is not allowed."
		else
			# wrap in magic
			obj = MagicNode.new(@object)
		end

		@scope_handler.relaxed_add_var(@name, obj)
		
		return obj
	end

	def output
		return unwrap.output
	end

	def bool_value
		return unwrap.bool_value
	end

	def eval
		return unwrap.eval
	end
end