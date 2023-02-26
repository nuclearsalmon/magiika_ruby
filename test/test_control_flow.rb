#!/usr/bin/env ruby

require_relative './testing_utils.rb'
require 'test/unit'


class TestControlFlow < Test::Unit::TestCase
  def test_if
    r = redirect_output {
      parse_new('if false: $"NOT OK"; $"OK"')
    }

    assert_equal("OK\n", r)

    r = redirect_output {
      parse_new('if true: $"OK"')
    }

    assert_equal("OK\n", r)
  end

  def test_else
    r = redirect_output {
      parse_new('if false: $"NOT OK"; else: $"OK"')
    }

    assert_equal("OK\n", r)
  end

  def test_elif
    r = redirect_output {
      parse_new("if false: $1; elif true: $2")
    }
    assert_equal("2\n", r)
  end

  def test_if_elif_else
    r = redirect_output {
      parse_new("if false: $1; elif true: $2; else: $3;")
    }
    assert_equal("2\n", r)
  end

  def test_if_elif_elif_else
    r = redirect_output {
      parse_new("if 0: $1; elif 0: $2; elif 0: $3;else: $4;")
    }
    assert_equal("4\n", r)
  end
end
