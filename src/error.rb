#!/usr/bin/env ruby

module Error
  class Magiika < StandardError
    def initialize(msg)
      super(msg)
    end
  end

  class Parse < Error::Magiika
    def initialize(msg, line=nil, col=nil)
      if line != nil && col != nil
        msg = "Error at line #{line}, col #{col}: #msg"
      elsif line != nil
        msg = "Error at line #{line}: #{msg}"
      #elsif col != nil
      #  msg = "Error at col #{col}: #{msg}"
      end
      super(msg)
    end
  end
  
  class NotImplemented < Error::Magiika
    def initialize(msg=nil)
      msg = "not implemented." + (msg == nil ? "" : " " + msg)
      super(msg)
    end
  end
  
  class UnsupportedOperation < Error::Magiika
    def initialize(msg)
      msg = "unsupported operation: " + msg
      super(msg)
    end
  end
  
  # Attempting to get a TypeNode class for a non-existant type
  class InvalidType < Error::Magiika
    def initialize(type)
      msg = "invalid type: `#{type}' is not a valid type."
      super(msg)
    end
  end
  
  class MismatchedType < Error::Magiika
    def initialize(value, type)
      msg = "invalid type: \n`#{value.inspect}'\n... is not a ...\n`#{type.inspect}'."
      super(msg)
    end
  end
  
  class NoSuchCast < Error::Magiika
    def initialize(from, into)
      into_type = into.expanded_type
      from_type = from.expanded_type
      msg = "cannot cast from `#{from_type}' into `#{into_type}'."
      super(msg)
    end
  end
  
  class AlreadyDefined < Error::Magiika
    def initialize(name)
      msg = "`#{name}' is already defined."
      super(msg)
    end
  end
  
  class UndefinedVariable < Error::Magiika
    def initialize(name, msg = nil)
      msg = "undefined variable `#{name}'." + (msg == nil ? "" : " " + msg)
      super(msg)
    end
  end
  
  class BadNrOfArgs < Error::Magiika
    def initialize(fnsig, badnrofargs)
      msg = "invalid number of arguments for `#{fnsig}': #{badnrofargs}."
      super(msg)
    end
  end
  
  class BadArgName < Error::Magiika
    def initialize(fnsig, badargname)
      msg = "invalid argument name for `#{fnsig}': #{badargname}."
      super(msg)
    end
  end

  class UnconstructedAbstract < Error::Magiika
    def initialize(name, msg=nil)
      msg = "Abstract `#{name}' not constructed." + (msg == nil ? "" : " " + msg)
      super(msg)
    end
  end

  class NotInitialized < Error::Magiika
    def initialize(msg=nil)
      msg = "Not initialized." + (msg == nil ? "" : " " + msg)
      super(msg)
    end
  end
end
