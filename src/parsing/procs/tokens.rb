#!/usr/bin/env ruby

# ✨ TOKENS
# ------------------------------------------------------------------------------
TOKENS_PROC = Proc.new do
  # whitespace
  token(/\r?\n/)                {:eol_tok}  # eol marker
  token(/;+/)                   {:eol_mark} # eol marker

  # comments
  token(/#.*$/)

  #token(/\/\/.*$/)
  token(/\/\*([^*]|\r?\n|(\*+([^*\/]|\r?\n)))*\*+\//)
  
  # literals
  token(/\d+\.\d+/)             {|t| t.to_f}        # flt literal
  token(/\d+/)                  {|t| t.to_i}        # int literal
  token(/true/)                 {|t| :true}         # bool literal
  token(/false/)                {|t| :false}        # bool literal
  token(/"([^"\\]*(?:\\.[^"\\]*)*)"/) {|t| t}       # str literal
  token(/'([^'\\]*(?:\\.[^'\\]*)*)'/) {|t| t}       # str literal

  # multi-character operators      
  token(/(\|\||&&|!\||!&|!^)/)  {|t| t}
  token(/(==|!=|>=|<=)/)        {|t| t}
  token(/(:=)/)                 {|t| t}
  token(/(\+\+|--|\/\/|<<|>>)/) {|t| t}
  token(/(->)/)                 {|t| t}

  # single-character operators
  token(/(=|\+|-|\*|\/|%|&|!|<|>)/) {|t| t}

  # symbols
  token(/(\[|\]|\(|\)|\{|\}|,|\.|:|\$)/) {|t| t}
  
  # names
  token(/[A-Za-z][A-Za-z_\-0-9]*/) {|t| t}

  # whitespace (run this last to allow for whitespace-sensitive tokens)
  token(/(\ |\t)+/)                                 # space or tab
end
