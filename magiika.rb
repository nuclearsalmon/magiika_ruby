#!/usr/bin/env ruby

require_relative './src/parsing/parser.rb'

ANSI_BANNER_SIXELS_PATH = "./resources/magiika_banner.sixels.ans"
ANSI_BANNER_SIXELS      = File.open(ANSI_BANNER_SIXELS_PATH, 'rb') {|f| f.read}
ANSI_RESET              = "\x1b[m"
ANSI_UNDERLINE_ON       = "\x1b[4m"
ANSI_UNDERLINE_OFF      = "\x1b[24m"
ANSI_BOLD_ACCENT_STYLE  = "\x1b[38;2;253;134;42;4m"
ANSI_ACCENT_STYLE       = "\x1b[38;2;253;134;42;3m"
ANSI_WARNING_STYLE      = "\x1b[38;2;235;59;47m"
ANSI_RELAXED_STYLE      = "\x1b[38;2;150;178;195m"


def _banner
  $stdout << ANSI_BANNER_SIXELS
  puts ANSI_BOLD_ACCENT_STYLE + " -    ⊹ M a g i i k a ₊+   - " + ANSI_RESET + 
    "\n"
  puts ANSI_ACCENT_STYLE +      "   a ⊹₊magical₊+ language~   " + ANSI_RESET + 
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
    @raw_print = false
    @show_empty = false
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
      if @parser.logger.level == Logger::DEBUG
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
    when "r"
      @raw_print = !@raw_print
      _notify("raw object printing " + _cond_to_tg(@raw_print) + "\n")
    when "s"
      @show_empty = !@show_empty
      _notify("show empty " + _cond_to_tg(@show_empty) + "\n")
    when "\n"
      _warn("unspecified command. try `##h'.")
    when "h"
      _notify(ANSI_UNDERLINE_ON + 
        "command list ⊹ ₊+          " + ANSI_UNDERLINE_OFF + "\n" + 
        "   `l' : toggle debug logging\n" +
        "   `e' : toggle pretty errors\n" +
        "   `a' : toggle error rescuing\n" +
        "   `r' : toggle raw object printing\n" +
        "   `s' : toggle show empty\n" +
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
      if input[0,2] == '##'
        _handle_special_commands(input)
      else
        begin
          result = @parser.parse(input)
        rescue Error::Magiika => error
          raise error if !@error_rescueing
          
          err_msg = error.to_s.strip + "\n"
          if !@pretty_error
            err_msg += "\n   " + error.backtrace.join("\n   ")
          end
          _warn(err_msg.strip)
          
          result = nil
        end

        if @raw_print
          $stdout << "☄️  " << ANSI_WARNING_STYLE << result << "\n\n"
        else
          if result == nil
            puts ''
          elsif result.class.method_defined?(:output) &&
            (result.class != EmptyNode || 
              (result.class == EmptyNode && @show_empty))
            result = result.output
            puts "⭐ #{result}\n\n"
          else
            puts ''
          end
        end
      end
    end
  rescue Interrupt
    puts "\n🌃 " + ANSI_RELAXED_STYLE + "leaving interactive mode" +
      ANSI_RESET + "\n\n"
  end
end

if __FILE__ == $0
  if ARGV.length == 0
    magiika = Magiika.new
    magiika.interactive
  else
    code = File.read(ARGV[0])
    magiika = Magiika.new
    #magiika.logger.level = Logger::DEBUG
    #_banner()
    magiika.parse(code)
    #result = magiika.parse(code)
    #puts "⭐ #{result}\n" if result
  end
end
