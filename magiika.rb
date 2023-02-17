#!/usr/bin/env ruby

require './src/parser.rb'


ANSI_RESET              = "\x1b[m"
ANSI_UNDERLINE_ON       = "\x1b[4m"
ANSI_UNDERLINE_OFF      = "\x1b[24m"
ANSI_BOLD_ACCENT_STYLE  = "\x1b[38;2;253;217;50;4m"
ANSI_ACCENT_STYLE       = "\x1b[38;2;253;217;50;3m"
ANSI_WARNING_STYLE      = "\x1b[38;2;247;175;1m"
ANSI_RELAXED_STYLE      = "\x1b[38;2;52;111;140m"


def _banner
  puts ANSI_BOLD_ACCENT_STYLE + " -   ⊹ M a g i i k a ₊+  - " + ANSI_RESET + 
    "\n"
  puts ANSI_ACCENT_STYLE +      "  powered by ⊹sparkles₊+!  " + ANSI_RESET + 
    "\n\n"
end

def _notify(msg)
  puts "🌠 " + ANSI_WARNING_STYLE + msg.to_s + ANSI_RESET + "\n"
end

def _warn(msg)
  puts "💫 " + ANSI_WARNING_STYLE + msg.to_s + ANSI_RESET + "\n"
end

def _cond_to_tg(condition)
  return condition ? "enabled" : "disabled"
end


class Magiika
  def initialize
    @parser = MagiikaParser.new.parser
    @parser.logger.level = Logger::WARN
    @pretty_error = true
    @error_rescueing = true
  end

  def logger
    @parser.logger
  end

  def parse(str)
    @parser.parse(str)
  end

  def _handle_special_commands(input)
    case input[2]
    when "l"
      if @parser.logger.level == Logger::DEBUG then
        @parser.logger.level = Logger::WARN
      else
        @parser.logger.level = Logger::DEBUG
      end
      _notify("debug logging " + 
        _cond_to_tg(@parser.logger.level == Logger::DEBUG) + "\n")
    when "e"
      @pretty_error = !@pretty_error
      _notify("pretty errors " + _cond_to_tg(@pretty_error) + "\n")
    when "a"
      @error_rescueing = !@error_rescueing
      _notify("error rescuing " + _cond_to_tg(@error_rescueing) + "\n")
    when "\n"
      _warn("unspecified command. try `##h'.")
    when "h"
      _notify(ANSI_UNDERLINE_ON + 
        "command list ⊹ ₊+          " + ANSI_UNDERLINE_OFF + "\n" + 
        "   `l' : toggle debug logging\n" +
        "   `e' : toggle pretty errors\n" +
        "   `a' : toggle error rescuing\n" +
        "   `h' : this help menu\n")
    else
      _warn("unknown command. try `##h'.\n")
    end
  end

  def interactive
    _banner()
    while true
      print '✨ '
      input = gets
      if input[0,2] == '##' then
        _handle_special_commands(input)
      else
        begin
          result = @parser.parse(input)
        rescue Exception => error
          raise error if !@error_rescueing
          
          err_msg = error.to_s.strip + "\n"
          if !@pretty_error then
            err_msg += "\n   " + error.backtrace.join("\n   ")
          end
          _warn(err_msg.strip)
          
          result = nil
        end

        if result == nil then
          puts
        else
          puts "⭐ #{result}\n\n"
        end

      end
    end
  rescue Interrupt
    puts "\n\n🌃 " + ANSI_RELAXED_STYLE + "leaving interactive mode" +
      ANSI_RESET + "\n\n"
  end
end

if __FILE__ == $0 then
  if ARGV.length == 0 then
    magiika = Magiika.new
    magiika.interactive
  else
    code = File.read(ARGV[0])

    _banner()

    # temporary code for until I make a print function in the language
    magiika = Magiika.new
    result = magiika.parse(code)
    puts "⭐ #{result}\n" if result
  end
end
