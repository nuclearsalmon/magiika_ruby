#!/usr/bin/env ruby

require_relative './testing_utils.rb'
require 'test/unit'


# IntNode
class TestIntNode < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new("int: v1; v1")
    assert_equal(EmptyNode.get_default, r.unwrap_only_class(MetaNode))
  end

  def test_positive_decl
    r = parse_new("int: i1 = 10000; i1")
    assert_equal(10000, r.unwrap_only_class(MetaNode).value)
    
    r = parse_new("int: i2 = 0; i2")
    assert_equal(0, r.unwrap_only_class(MetaNode).value)

    r = parse_new("int: i3 = " + FIXNUM_MAX.to_s + "; i3")
    assert_equal(FIXNUM_MAX, r.unwrap_only_class(MetaNode).value)
  end

  def test_negative_decl
    r = parse_new("int: i1 = -10000; i1")
    assert_equal(-10000, r.unwrap_only_class(MetaNode).value)

    r = parse_new("int: i2 = " + FIXNUM_MIN.to_s + "; i2")
    assert_equal(FIXNUM_MIN, r.unwrap_only_class(MetaNode).value)
  end
end


# FltNode
class TestFltNode < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new("flt: v1; v1")
    assert_equal(EmptyNode.get_default, r.unwrap_only_class(MetaNode))
  end

  def test_positive_decl
    r = parse_new("flt: f1 = 10000.123; f1")
    assert_equal(10000.123, r.unwrap_only_class(MetaNode).value)
    
    r = parse_new("flt: f2 = 0.321; f2")
    assert_equal(0.321, r.unwrap_only_class(MetaNode).value)
  end

  def test_negative_decl
    r = parse_new("flt: f1 = -10000.123; f1")
    assert_equal(-10000.123, r.unwrap_only_class(MetaNode).value)
  end
end


# BoolNode
class TestBoolNode < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new("bool: v1; v1")
    assert_equal(EmptyNode.get_default, r.unwrap_only_class(MetaNode))
  end

  def test_bool_decl
    r = parse_new("bool: v_t = true; v_t")
    assert_equal(BoolNode.new(true).value, r.unwrap_only_class(MetaNode).value)

    r = parse_new("bool: v_f = false; v_f")
    assert_equal(BoolNode.new(false).value, r.unwrap_only_class(MetaNode).value)
  end
end


# Magic
class TestMagic < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new("empty: v1; v1")
    assert_equal(MetaNode, r.class)
    assert_equal(true, r.empty)
    assert_equal(true, r.magic?)
    assert_equal(EmptyNode, r.unwrap_only_class(MetaNode).class)
  end

  def test_int_decl
    r = parse_new(": v1 = 100; v1")
    assert_equal(100, r.unwrap_only_class(MetaNode).value)
  end

  def test_flt_decl
    r = parse_new(": v1 = 100.0; v1")
    assert_equal(100.0, r.unwrap_only_class(MetaNode).value)
  end

  def test_bool_decl
    r = parse_new(": v_t = true; v_t")
    assert_equal(true, r.unwrap_only_class(MetaNode).value)

    r = parse_new(": v_f = false; v_f")
    assert_equal(false, r.unwrap_only_class(MetaNode).value)
  end
end
