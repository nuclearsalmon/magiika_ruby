#!/usr/bin/env ruby

require_relative '../nodes.rb'


class Print < ContainerTypeNode  #FIXME: this should be an operator
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
