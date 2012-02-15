require "agent"
require "behaviour"
require "container"
require "aclmessage"


class JakeBehaviour <Behaviour
  def initialize
    @skip = false
  end
  def skip
    @skip
  end
  def action
    @agent.receive { |msg|
      puts "<<<"
      puts msg
      @skip = true
    }
  end
end

class JakeAgent < Agent
  def initialize(container)
    super("Jake", container)
  end
  def setup
    msg = ACLMessage.new(ACLMessage.REQUEST, {
                           "sender" => @aid,
                           "language" => "English",
                           "ontology" => "Loving",
                           "content" => "Hello, I love u",
                         })
    msg['receivers'] << AID.new("Mary")
    puts ">>>"
    puts msg
    send_msg(msg)
    add_behaviour(JakeBehaviour.new)
  end
end

Thread.abort_on_exception = true
p = Container.new("Jake", "localhost:8888", "localhost:7777")
s = p.start_service { |p|
  p.add_agent(JakeAgent.new(p))
}

t = Thread.new(p) { |platform|
  #gets
  sleep 5
  platform.stop_service
  puts "finished"  
}

t.join
s.join
