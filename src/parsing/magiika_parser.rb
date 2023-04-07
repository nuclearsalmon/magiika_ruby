#!/usr/bin/env ruby

require_relative '../error.rb'
require_relative '../utils.rb'
require_relative '../safety.rb'
require_relative '../nodes.rb'
require_relative '../program.rb'
require_relative '../scope.rb'
require_relative '../variable.rb'
require_relative '../functions/function_utils.rb'
require_relative '../functions/function_def.rb'
require_relative '../functions/function_call.rb'
require_relative '../classes/class_def.rb'
require_relative '../classes/class_instance.rb'
require_relative '../classes/class_call.rb'

require_relative './parser.rb'

require_relative './procs/tokens.rb'
require_relative './procs/commons.rb'
require_relative './procs/program.rb'
require_relative './procs/types.rb'
require_relative './procs/variables.rb'
require_relative './procs/functions.rb'
require_relative './procs/conditions.rb'
require_relative './procs/expressions.rb'
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
      instance_eval &CLASSES_PROC
      instance_eval &VARIABLES_PROC
      instance_eval &FUNCTIONS_PROC
      instance_eval &CONDITIONS_PROC
      instance_eval &EXPRESSIONS_PROC
    end
  end
end
