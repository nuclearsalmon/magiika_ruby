#!/usr/bin/env ruby

class MetaNode < TypeNode
  attr_reader :node, :type
  attr_reader :accessor, :empty, :static, :abstract, :const
  attr_reader :specification

  def initialize(attribs, node=nil, type=nil, specification=false)
    @accessor = :publ
    @empty = type.class == EmptyNode
    @const = false
    @static = false
    @abstract = false
    @node = nil  # will set using `set_node(node)' later
    @type = type.class == EmptyNode ? nil : type
    @specification = specification

    if !@specification && !attribs.include?(:magic) && @type.class == EmptyNode
      raise Error::Magiika.new("Missing type yet not defined as magic.")
    end
    
    attrib_dupl_check = []
    attribs.each {
      |attrib|
      # dublication check
      if attrib_dupl_check.include?(attrib)
        raise Error::Magiika.new("Duplicate attribute `#{attrib}'.")
      end
      attrib_dupl_check << attrib

      case attrib
      when :magic
        nil  # do nothing
      when :empty
        @empty = true
      when :publ, :prot, :priv
        @accessor = attrib
      when :const
        @const = true
      when :stat
        @static = true
      when :abst
        @abstract = true
      else
        raise Error::Magiika.new("Unsupported attribute `#{attrib}'.")
      end
    }

    set_node(node)
  end

  def set_node(node)
    if node.class <= MetaNode
      raise Error::Magiika.new('Nested MetaNodes are not allowed.')
    end

    if @specification
      if @node != nil or node != nil
        raise Error::Magiika.new('Cannot assign a node to a metaspec.')
      end
      return  # skip the below code
    end

    if node == nil
      raise Error::Magiika.new('Nil node values are forbidden.') if !@specification
    elsif !(node.class <= TypeNode)
      raise Error::Magiika.new("Node is not a TypeNode: #{node}.")
    elsif node.class <= EmptyNode
      if !@empty && !self.magic?
        raise Error::Magiika.new('Attempted to set to nil when not empty.')
      end
    else
      if !self.magic? && !TypeSafety.obj_is_type?(node, @type, true)
        raise Error::MismatchedType.new(node, @type)
      end
    end
    
    @node = node
  end

  def magic?
    return @type == nil
  end

  def public?
    return @accessor == :publ
  end

  def protected?
    return @accessor == :prot
  end

  def private?
    return @accessor == :priv
  end

  def unwrap
    return @node != nil ? @node : EmptyNode.get_default()
  end

  def eval(scope)
    self.set_node(@node.eval(scope))
    return self
  end

  def bool_eval?(scope)
    return @node.bool_eval?(scope)
  end

  def self.type
    return 'meta'
  end

  def output(scope)
    return "#{@node.respond_to?(:output) ? @node.output(scope) : @node}\n" \
      + "#{@specification ? 'metaspec' : 'meta'}: " \
      + "<#{@accessor}#{' empty' if @empty} #{@type == nil ? 'magic' : @type}" \
      + "#{' const' if @const}#{' static' if @static}#{' abstract' if @abstract}>" \
  end
end
