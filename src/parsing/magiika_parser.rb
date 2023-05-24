#!/usr/bin/env ruby

require_relative '../error.rb'
require_relative '../lang/utils.rb'
require_relative '../lang/nodes/base_nodes.rb'
require_relative '../lang/nodes/meta_node.rb'
require_relative '../lang/nodes/types/bool.rb'
require_relative '../lang/nodes/types/empty.rb'
require_relative '../lang/nodes/types/flt.rb'
require_relative '../lang/nodes/types/int.rb'
require_relative '../lang/nodes/types/str.rb'
require_relative '../lang/nodes/program_nodes.rb'
require_relative '../lang/safety.rb'
require_relative '../lang/scope.rb'
require_relative '../lang/variable.rb'
require_relative '../lang/functions/function_utils.rb'
require_relative '../lang/functions/function_def.rb'
require_relative '../lang/functions/function_call.rb'
require_relative '../lang/functions/function_inst.rb'
require_relative '../lang/classes/class_def.rb'
require_relative '../lang/classes/class_call.rb'
require_relative '../lang/classes/class_base.rb'
require_relative '../lang/classes/class_inst.rb'

require_relative './parser.rb'

require_relative './procs/tokens.rb'
require_relative './procs/commons.rb'
require_relative './procs/types.rb'
require_relative './procs/program.rb'
require_relative './procs/objects.rb'
require_relative './procs/conditions.rb'
require_relative './procs/expressions.rb'
require_relative './procs/functions.rb'
require_relative './procs/classes.rb'

class MagiikaParser
  attr_reader :parser

  def initialize
    @parser = Parser.new("Magiika") do
      # ✨ TOKENS
      # ------------------------------------------------------------------------

      instance_eval &TOKENS_PROC


      # ✨ MATCHES
      # ------------------------------------------------------------------------

      instance_eval &COMMONS_PROC
      instance_eval &TYPES_PROC
      instance_eval &PROGRAM_PROC
      instance_eval &OBJECTS_PROC
      instance_eval &CLASSES_PROC
      instance_eval &FUNCTIONS_PROC
      instance_eval &CONDITIONS_PROC
      instance_eval &EXPRESSIONS_PROC
    end
  end
end
