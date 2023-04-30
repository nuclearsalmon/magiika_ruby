#!/usr/bin/env ruby


class MagicNode < ContainerTypeNode
  def initialize(value)
    if !(value.class < TypeNode)
      raise Error::Magiika.new('a MagicNode must be instansiated with a TypeNode.')
    elsif value.unwrap_contains_class?(MagicNode, true)
      raise Error::Magiika.new('a MagicNode cannot contain another MagicNode.')
    end

    super(value)
  end

  def self.get_default
    return MagicNode.new(EmptyNode.get_default)
  end

  def eval(scope)
    return @value.eval(scope)
  end

  def bool_eval?(scope)
    return @value != EmptyNode.get_default
  end

  def unwrap
    return @value
  end

  def output(scope)
    return @value.output(scope)
  end

  def self.type
    return 'magic'
  end

  def ===(other)
    return !(other.unwrap_contains_class?(MagicNode, true))
  end
end
