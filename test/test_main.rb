#!/usr/bin/env ruby

require 'test/unit'
require './main.rb'


FIXNUM_MAX = (2**(0.size * 8 -2) -1)
FIXNUM_MIN = -(2**(0.size * 8 -2))


# Shorthand function for creating a new Magiika environment
# and evaluating a string.
def parse(code)
  Magiika.new.parse(code)
end


# IntNode
class TestIntNode < Test::Unit::TestCase
  def test_positive_decl
    r = parse("int: i1 = 10000; i1")
    assert_equal(10000, r)
    
    r = parse("int: i2 = 0; i2")
    assert_equal(0, r)

    r = parse("int: i3 = " + FIXNUM_MAX.to_s + "; i3")
    assert_equal(FIXNUM_MAX, r)
  end

  def test_negative_decl
    r = parse("int: i1 = -10000; i1")
    assert_equal(-10000, r)

    r = parse("int: i2 = " + FIXNUM_MIN.to_s + "; i2")
    assert_equal(FIXNUM_MIN, r)
  end
end


# FltNode
class TestFltNode < Test::Unit::TestCase
  def test_positive_decl
    r = parse("flt: f1 = 10000.123; f1")
    assert_equal(10000.123, r)
    
    r = parse("flt: f2 = 0.321; f2")
    assert_equal(0.321, r)
  end

  def test_negative_decl
    r = parse("flt: f1 = -10000.123; f1")
    assert_equal(-10000.123, r)
  end
end


# BoolNode
class TestBoolNode < Test::Unit::TestCase
  def test_bool_decl
    r = parse("bool: v_t = true; v_t")
    assert_equal(true, r)

    r = parse("bool: v_f = false; v_f")
    assert_equal(false, r)
  end
end


# MagicNode
class TestMagicNode < Test::Unit::TestCase
  def test_int_decl
    r = parse(": v1 = 100; v1")
    assert_equal(100, r)
  end

  def test_flt_decl
    r = parse(": v1 = 100.0; v1")
    assert_equal(100.0, r)
  end

  def test_bool_decl
    r = parse(": v_t = true; v_t")
    assert_equal(true, r)

    r = parse(": v_f = false; v_f")
    assert_equal(false, r)
  end
end
