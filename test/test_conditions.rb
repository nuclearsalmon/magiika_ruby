#!/usr/bin/env ruby

require_relative './testing_utils.rb'
require 'test/unit'


# And
class TestAnd < Test::Unit::TestCase
  def test_bool
    r = parse_new("true and false")
    assert_equal(BoolNode.new(false), r)

    r = parse_new("false and true")
    assert_equal(BoolNode.new(false), r)

    r = parse_new("true and true")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("false and false")
    assert_equal(BoolNode.new(false), r)
  end

  def test_various_builtin_types
    r = parse_new("0 and 0")
    assert_equal(BoolNode.new(false), r)

    r = parse_new("1 and 0")
    assert_equal(BoolNode.new(false), r)

    r = parse_new("1 and 1")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("1.0 and 1.8")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("0.1 and 0")
    assert_equal(BoolNode.new(false), r)

    r = parse_new("0.0 and 0.0")
    assert_equal(BoolNode.new(false), r)
  end

  def test_chained
    r = parse_new("1 and false and 1")
    assert_equal(BoolNode.new(false), r)

    r = parse_new("1 and 1 and true")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("1 and 1 and false and true")
    assert_equal(BoolNode.new(false), r)
  end
end


# Or
class TestOr < Test::Unit::TestCase
  def test_bool
    r = parse_new("true or false")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("false or true")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("true or true")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("false or false")
    assert_equal(BoolNode.new(false), r)
  end

  def test_various_builtin_types
    r = parse_new("0 or 0")
    assert_equal(BoolNode.new(false), r)

    r = parse_new("1 or 0")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("1 or 1")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("1.0 or 1.8")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("0.1 or 0")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("0.0 or 0.0")
    assert_equal(BoolNode.new(false), r)
  end

  def test_chained
    r = parse_new("1 or false or 1")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("1 or 1 or true")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("1 or 1 or false or true")
    assert_equal(BoolNode.new(true), r)
  end
end


# Mixed
class TestMixedConditions < Test::Unit::TestCase
  def test_chained
    r = parse_new("1 and 1 or false")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("1 or 1 and false")
    assert_equal(BoolNode.new(true), r)

    r = parse_new("1 and 1 or false and true")
    assert_equal(BoolNode.new(true), r)
 end
end