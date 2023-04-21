#!/usr/bin/env ruby

require_relative './testing_utils.rb'
require 'test/unit'


# IntNode
class TestIntNode < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new("int: v1; v1")
    assert_equal(0, r.unwrap.value)
  end

  def test_positive_decl
    r = parse_new("int: i1 = 10000; i1")
    assert_equal(10000, r.unwrap.value)
    
    r = parse_new("int: i2 = 0; i2")
    assert_equal(0, r.unwrap.value)

    r = parse_new("int: i3 = " + FIXNUM_MAX.to_s + "; i3")
    assert_equal(FIXNUM_MAX, r.unwrap.value)
  end

  def test_negative_decl
    r = parse_new("int: i1 = -10000; i1")
    assert_equal(-10000, r.unwrap.value)

    r = parse_new("int: i2 = " + FIXNUM_MIN.to_s + "; i2")
    assert_equal(FIXNUM_MIN, r.unwrap.value)
  end
end


# FltNode
class TestFltNode < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new("flt: v1; v1")
    assert_equal(0.0, r.unwrap.value)
  end

  def test_positive_decl
    r = parse_new("flt: f1 = 10000.123; f1")
    assert_equal(10000.123, r.unwrap.value)
    
    r = parse_new("flt: f2 = 0.321; f2")
    assert_equal(0.321, r.unwrap.value)
  end

  def test_negative_decl
    r = parse_new("flt: f1 = -10000.123; f1")
    assert_equal(-10000.123, r.unwrap.value)
  end
end


# BoolNode
class TestBoolNode < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new("bool: v1; v1")
    assert_equal(BoolNode.new(false), r)
  end

  def test_bool_decl
    r = parse_new("bool: v_t = true; v_t")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("bool: v_f = false; v_f")
    assert_equal(BoolNode.new(false), r)
  end
end


# MagicNode
class TestMagicNode < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new(": v1; v1")
    assert_equal(MagicNode, r.class)
    assert_equal(EmptyNode, r.unwrap.class)
  end

  def test_int_decl
    r = parse_new(": v1 = 100; v1")
    assert_equal(100, r.unwrap.value)
  end

  def test_flt_decl
    r = parse_new(": v1 = 100.0; v1")
    assert_equal(100.0, r.unwrap.value)
  end

  def test_bool_decl
    r = parse_new(": v_t = true; v_t")
    assert_equal(true, r.unwrap.value)

    r = parse_new(": v_f = false; v_f")
    assert_equal(false, r.unwrap.value)
  end
end
