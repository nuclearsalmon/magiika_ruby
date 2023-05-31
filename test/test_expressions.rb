#!/usr/bin/env ruby

require_relative './testing_utils.rb'
require 'test/unit'


class TestMathExpressions < Test::Unit::TestCase
  def test_basic_add_sub
    r = parse_new("-1-8+9")
    assert_equal(0, r.value)
  end

  def test_basic_math
    r = parse_new("1+1*3")
    assert_equal(4, r.value)
  end

  def test_groups
    r = parse_new("1+(1*3)")
    assert_equal(4, r.value)
  end
end
