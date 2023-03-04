#!/usr/bin/env ruby

require_relative './rdparse.rb'

require_relative './procs/tokens.rb'
require_relative './procs/commons.rb'
require_relative './procs/program.rb'
require_relative './procs/types.rb'
require_relative './procs/variables.rb'
require_relative './procs/functions.rb'
require_relative './procs/conditions.rb'
require_relative './procs/expressions.rb'

require_relative '../error.rb'
require_relative '../safety.rb'
require_relative '../nodes.rb'
require_relative '../program.rb'
require_relative '../scope.rb'
require_relative '../variable.rb'
require_relative '../functions.rb'
require_relative '../classes.rb'


class MagiikaParser
  attr_reader :parser

  def initialize
    @scope_handler = ScopeHandler.new
    # create a variable so we can use the ScopeHandler inside the parser block
    scope_handler = @scope_handler
    
    @parser = Parser.new("Magiika") do
      # ✨ TOKENS
      # ------------------------------------------------------------------------

      self.instance_eval &TOKENS_PROC


      # ✨ MATCHES
      # ------------------------------------------------------------------------

      self.instance_eval &COMMONS_PROC
      self.instance_exec scope_handler, &PROGRAM_PROC
      self.instance_eval &TYPES_PROC
      self.instance_exec scope_handler, &VARIABLES_PROC
      self.instance_exec scope_handler, &FUNCTIONS_PROC
      self.instance_eval &CONDITIONS_PROC
      self.instance_eval &EXPRESSIONS_PROC
    end
  end
end
