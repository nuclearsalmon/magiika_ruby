#!/usr/bin/env ruby

require_relative './testing_utils.rb'
require 'test/unit'


class TestDeclaration < Test::Unit::TestCase
  def test_empty_declaration
    r = parse_new(":e;e")
    assert_equal(MagicNode, r.class)
    assert_equal(EmptyNode, r.unwrap.class)
  end

  def test_builtin_declaration
    magiika = Magiika.new

    r = magiika.parse(":i=1;i")
    assert_equal(IntNode.new(1), r)

    r = magiika.parse(":f=1.7;f")
    assert_equal(FltNode.new(1.7), r)

    r = magiika.parse(":b=true;b")
    assert_equal(BoolNode.new(true), r.unwrap)

    r = magiika.parse(":c='!';c")
    assert_equal(StrNode.new("!"), r.unwrap)

    r = magiika.parse(":s=\"!!!\";s")
    assert_equal(StrNode.new("!!!"), r.unwrap)
  end


  def test_builtin_magic_redeclare_same_type
    magiika = Magiika.new

    r = magiika.parse(":e = 100; e")
    assert_equal(IntNode.new(100), r)

    r = magiika.parse("e := 777; e")
    assert_equal(IntNode.new(777), r)
  end

  def test_builtin_magic_redeclare_different_type
    magiika = Magiika.new

    r = magiika.parse(":e = 08.9002; e")
    assert_equal(FltNode.new(8.9002), r)

    r = magiika.parse("e := true; e")
    assert_equal(BoolNode.new(true), r)
  end
end

class TestAssignment
  def test_builtin_reassign
    magiika = Magiika.new

    r = magiika.parse(":i=1;i")
    assert_equal(IntNode.new(1), r)

    r = magiika.parse(":f=1.7;f")
    assert_equal(FltNode.new(1.7), r)

    r = magiika.parse(":b=true;b")
    assert_equal(BoolNode.new(true), r)

    r = magiika.parse(":c='!';c")
    assert_equal(StrNode.new("!"), r)

    r = magiika.parse(":s=\"!!!\";s")
    assert_equal(StrNode.new("!!!"), r)

    # ---

    r = magiika.parse("i=2;i")
    assert_equal(IntNode.new(2), r)

    r = magiika.parse("f=8.7;f")
    assert_equal(FltNode.new(8.7), r)

    r = magiika.parse("b=false;b")
    assert_equal(BoolNode.new(false), r)

    r = magiika.parse("c='a';c")
    assert_equal(ChrNode.new("a"), r)

    r = magiika.parse("s=\"abc\";s")
    assert_equal(StrNode.new("abc"), r)
  end
end
