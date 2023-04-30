#!/usr/bin/env ruby

require 'singleton'


class EmptyNode < TypeNode
  include Singleton

  def self.get_default
    return self.instance
  end

  def eval(scope)
    return self
  end

  def output(scope)
    return type
  end

  def self.type
    return 'empty'
  end
end
