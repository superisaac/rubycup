#!/usr/bin/env ruby

#
# The match platform of Ruby CUP
# Written by Zeng Ke
#

require "match"
require "config"
require "observer_drb"
require "player.rb"
require "getoptlong"

#
# run the match with two teams' wisdom
#
def run_match(teama, teamb)

  Thread.abort_on_exception = true
  p = Platform.new("Playground", "localhost:7777")
  #
  # Start platform
  #
  s = p.start_service { |p|
   
    Config.teama_names.each { |t|
      p.add_agent(PlayerAgent.new(t, p, teama))
    }

    Config.teamb_names.each { |t|
      p.add_agent(PlayerAgent.new(t, p, teamb))
    }
    
    sleep 1
    p.add_agent(MatchAgent.new("Match", p))
    p.add_agent(ObserverDRbAgent.new("Observer.DRb", p))
  } 
  s.join
end
def help
  ws = Dir.entries("wisdoms").grep(/^[^.]/).join(", ")
  puts <<HELP
Usage: #{$0} [option]*
Options:
    --teama <wisdom>, -a<wisdom>   the wisdom of team A, which can be one of {#{ws}}
    --teamb <wisdom>, -b<wisdom>   the wisdom of team B, which can be one of {#{ws}}    
    --help, -h                     show this information
HELP
end

if __FILE__ == $0
  #
  # Handle argument options
  #
  parser = GetoptLong.new
  parser.set_options(
      ["--teama", "-a", GetoptLong::REQUIRED_ARGUMENT],
      ["--teamb", "-b", GetoptLong::REQUIRED_ARGUMENT],
      ["--help", "-h", GetoptLong::NO_ARGUMENT] )

  $TEAMA = $TEAMB = "stupid"
  
  begin    
    parser.each_option do |name, arg|
      if name =~ /help/        
        exit 0      
      else
        a = "$#{((name.sub /^--/, '' ).gsub /-/, '_').upcase} = '#{arg}'"
        eval a
      end
    end
  rescue Exception=>e
    help
    exit 0
  end
  run_match($TEAMA, $TEAMB)
end
