#!/usr/bin/env ruby

# ✨ TYPES
# ------------------------------------------------------------------------------
TYPES_PROC = Proc.new do
  # ✨ Attributes
  # --------------------------------------------------------

  rule :accessor do
    match('public')                     {:publ}
    match('publ')                       {:publ}
    match('private')                    {:priv}
    match('priv')                       {:priv}
    match('protected')                  {:prot}
    match('prot')                       {:prot}
  end

  rule :static do
    match('static')                     {:stat}
    match('stat')                       {:stat}
  end

  rule :abstract do
    match('abstract')                   {:abst}
    match('abst')                       {:abst}
  end

  rule :const do
    match('const')                      {:const}
  end

  rule :magic do
    match('magic')                      {:magic}
  end

  rule :empty do
    match('empty')                      {:empty}
    match('!')                          {:empty}
  end


  # ✨ Types and attributed types 
  # --------------------------------------------------------

  rule :type do
    match(:member_access)               {|acc| RetrieveTypeStmt.new(acc)}
  end

  rule :type_list do
    match(:type, :type_list)            {|type, types| [type].concat(types)}
    match(:type)                        {|type| [type]}
  end

  rule :type_attrib do
    match(:magic)
    match(:empty)
    match(:const)
  end

  rule :type_attribs do
    match(:type_attrib, :type_attribs)  {|attrib, attribs| [attrib].concat(attribs)}
    match(:type_attrib)                 {|attrib|          [attrib]}
  end

  rule :attributed_type do
    match(:type_attribs, :type) {|attribs,type| [attribs, type]}
    match(:type_attribs)        {|attribs|      [attribs, nil]}
    match(:type)                {|type|         [[], type]}
  end
  
  rule :type_ident do
    match(':')                    {[[], nil]}
    match(:attributed_type, ':')  {|ident,_| ident}
  end


  # ✨ Builtins
  # --------------------------------------------------------

  rule :name do
    match(/([A-Za-z_][A-Za-z0-9_]*)/)
  end
  
  rule :value do
    match(:literal)
    match(:member_access)
    match('(', :cond, ')')      {|_,cond,_| cond}
  end
  
  rule :literal do
    match('empty')              {EmptyNode.new}
    match(:flt)
    match(:int)
    match(:bool)
    match(:str)
  end

  rule :flt do
    match(Float)                {|flt| FltNode.new(flt)}
  end

  rule :int do
    match(Integer)              {|int| IntNode.new(int)}
  end

  rule :bool do
    match(:true)                {BoolNode.new(true)}
    match(:false)               {BoolNode.new(false)}
  end

  rule :str do
    match(/"([^"\\]*(?:\\.[^"\\]*)*)"/) {|str| StrNode.new(str[1..-2])}
    match(/'([^'\\]*(?:\\.[^'\\]*)*)'/) {|str| StrNode.new(str[1..-2])}
  end
end
