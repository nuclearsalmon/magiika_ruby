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


# Attempting to get a TypeNode class for a non-existant type
class MagiikaInvalidTypeError < MagiikaError
  def initialize(type)
    msg = "invalid type: `#{type}' is not a valid `#{TypeNode}'."
    super(msg)
  end
end


class MagiikaMismatchedTypeError < MagiikaError
  def initialize(value, type)
    msg = "invalid type: `#{value}' is not a `#{type}'."
    super(msg)
  end
end


class MagiikaNoSuchCastError < MagiikaError
  def initialize(from, into)
    into_type = into.expanded_type
    from_type = from.expanded_type
    msg = "cannot cast from `#{from_type}' into `#{into_type}'."
    super(msg)
  end
end


class MagiikaAlreadyDefinedError < MagiikaError
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


class MagiikaBadNrOfArgsError < MagiikaError
  def initialize(fnsig, badnrofargs)
    msg = "invalid number of arguments for `#{fnsig}': #{badnrofargs}."
    super(msg)
  end
end


class MagiikaBadArgNameError < MagiikaError
  def initialize(fnsig, badargname)
    msg = "invalid argument name for `#{fnsig}': #{badargname}."
    super(msg)
  end
end
