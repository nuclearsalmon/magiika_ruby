#!/usr/bin/env ruby

require_relative './testing_utils.rb'
require 'test/unit'


class TestDeclaration < Test::Unit::TestCase
  def test_empty_decl
    r = parse_new(":e;e")
    assert_equal(MagicNode, r.class)
    assert_equal(EmptyNode, r.unwrap.class)
  end

  def test_builtin_decl
    magiika = Magiika.new

    r = magiika.parse(":i=1;i")
    assert_equal(IntNode.new(1), r.value)

    r = magiika.parse(":f=1.7;f")
    assert_equal(FltNode.new(1.7), r.value)

    r = magiika.parse(":b=true;b")
    assert_equal(BoolNode.new(true), r.value)

    r = magiika.parse(":c='!';c")
    assert_equal(ChrNode.new("!"), r.value)

    r = magiika.parse(":s=\"!!!\";s")
    assert_equal(StrNode.new("!!!"), r.value)
  end

  def test_builtin_assign
    magiika = Magiika.new

    r = magiika.parse(":i=1;i")
    assert_equal(IntNode.new(1), r.value)

    r = magiika.parse(":f=1.7;f")
    assert_equal(FltNode.new(1.7), r.value)

    r = magiika.parse(":b=true;b")
    assert_equal(BoolNode.new(true), r.value)

    r = magiika.parse(":c='!';c")
    assert_equal(ChrNode.new("!"), r.value)

    r = magiika.parse(":s=\"!!!\";s")
    assert_equal(StrNode.new("!!!"), r.value)

    # ---

    r = magiika.parse("i=2;i")
    assert_equal(IntNode.new(2), r.value)

    r = magiika.parse("f=8.7;f")
    assert_equal(FltNode.new(8.7), r.value)

    r = magiika.parse("b=false;b")
    assert_equal(BoolNode.new(false), r.value)

    r = magiika.parse("c='a';c")
    assert_equal(ChrNode.new("a"), r.value)

    r = magiika.parse("s=\"abc\";s")
    assert_equal(StrNode.new("abc"), r.value)
  end
end
