require "mas/mas"
#module Test
  include MAS
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
                           "reply-with" => "Jake id vv j"
                         })
      msg['receivers'] << AID.new("Mary")
      puts "Jake>>>Mary"
      puts msg
      send_msg(msg)
    end
  end

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
      puts "Mary>>>Jake"
      puts reply
      @agent.send_msg(reply)
      @skip = true
    end

    def action
      if not @skip
        pp = proc { |msg| on_request(msg) }
        @agent.receive_callback(pp, MessageSelector.match_performative(ACLMessage.REQUEST))
        puts "added pp"
      end
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

  def test1
    Thread.abort_on_exception = true
    p = Platform.new("LovingRoom", "localhost:7777")
    s = p.start_service { |p|
      p.add_agent(MaryAgent.new(p))
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
  end
#end

test1
