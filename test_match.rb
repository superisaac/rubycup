require "match"
#require "stupid"
require "observer_drb"
require 'config'

def test_match(brain_file)
  if brain_file =~ /\.rb$/
    load(brain_file)
  else
    load("#{brain_file}.rb")
  end
  Thread.abort_on_exception = true
  p = Platform.new("Playground", "localhost:7777")
  s = p.start_service { |p|
    Config.player_names.each { |t|
      p.add_agent(PlayerAgent.new(t, p, *behaviours))
    }
    sleep 1
    p.add_agent(MatchAgent.new(p))
    p.add_agent(ObserverDrbAgent.new(p))
  } 
  s.join
end

if __FILE__ == $0
  test_match ARGV[0]
end
