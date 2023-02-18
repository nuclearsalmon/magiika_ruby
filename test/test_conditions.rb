#!/usr/bin/env ruby

require_relative './testing_utils.rb'
require 'test/unit'


# And
class TestAnd < Test::Unit::TestCase
  def test_bool
    r = parse_new("true and false")
    assert_equal(false, r)

    r = parse_new("false and true")
    assert_equal(false, r)

    r = parse_new("true and true")
    assert_equal(true, r)

    r = parse_new("false and false")
    assert_equal(false, r)
  end

  def test_various_builtin_types
    r = parse_new("0 and 0")
    assert_equal(false, r)

    r = parse_new("1 and 0")
    assert_equal(false, r)

    r = parse_new("1 and 1")
    assert_equal(true, r)

    r = parse_new("1.0 and 1.8")
    assert_equal(true, r)

    r = parse_new("0.1 and 0")
    assert_equal(false, r)

    r = parse_new("0.0 and 0.0")
    assert_equal(false, r)
  end

  def test_chained
    r = parse_new("1 and 1 or false")
    assert_equal(true, r)

    r = parse_new("1 or 1 and false")
    assert_equal(false, r)

    r = parse_new("1 and 1 or false and true")
    assert_equal(true, r)
  end
end
