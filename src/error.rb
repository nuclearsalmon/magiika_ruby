#!/usr/bin/env ruby


class MagiikaError < StandardError
  def initialize(msg)
    super(msg)
  end
end


class MagiikaParseError < MagiikaError
  def initialize(msg)
    msg = "parsing error: " + msg
    super(msg)
  end
end


class MagiikaNotImplementedError < MagiikaError
  def initialize(msg=nil)
    msg = "not implemented." + (msg == nil ? "" : " " + msg)
    super(msg)
  end
end


class MagiikaUnsupportedOperationError < MagiikaError
  def initialize(msg)
    msg = "unsupported operation: " + msg
    super(msg)
  end
end


class MagiikaInvalidTypeError < MagiikaError
  def initialize(value, type)
    msg = "invalid type: `#{value}' is not a `#{type}'."
    super(msg)
  end
end


class MagiikaMismatchedTypeCastError < MagiikaError
  def initialize(from, into)
    into_type = get_expanded_type(into)
    from_type = get_expanded_type(from)
    msg = "mismatched types: `#{into_type}' from `#{from_type}'."
    super(msg)
  end
end


class MagiikaDefinedVariableError < MagiikaError
  def initialize(name)
    msg = "`#{name}' is already defined."
    super(msg)
  end
end


class MagiikaUndefinedVariableError < MagiikaError
  def initialize(name)
    msg = "undefined variable `#{name}'."
    super(msg)
  end
end
