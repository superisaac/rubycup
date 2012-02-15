require "agent"
require "behaviour"
require "container"
require "aclmessage"

class MaryBehaviour < Behaviour
  def initialize
    @skip = false
  end

  def skip
    @skip
  end

  def on_request(msg)
    reply = msg.gen_reply(ACLMessage.INFORM, AID.new(@agent.name))
    reply['content'] = "I Love u too"
    puts ">>>"
    puts reply
    @agent.send_msg(reply)
    @skip = true
  end

  def action
    pp = proc { |msg| 
      puts "<<<"
      puts msg
      on_request(msg) 
    }
    @agent.receive_callback(pp, MessageSelector.match_performative(ACLMessage.REQUEST))
  end
end

class MaryAgent < Agent
  def initialize(container)
    super("Mary", container)
  end
  def setup
    add_behaviour(MaryBehaviour.new)
  end
end

Thread.abort_on_exception = true
p = Platform.new("LovingRoom", "localhost:7777")
s = p.start_service { |p|
  p.add_agent(MaryAgent.new(p))
}

t = Thread.new(p) { |platform|
  #gets
  sleep 10

  platform.stop_service
  puts "finished"  
}

t.join
s.join
