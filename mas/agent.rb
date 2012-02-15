#require 'aid'
require 'drb'
module MAS
class Agent
  attr_reader :aid, :arguments
  def initialize(name, container, *arguments)
    
    @behaviours = Array.new
    @container = container
    @aid = AID.new name
    @aid.addresses << "#{name}@#{@container.address}"
    @arguments = arguments
  end

  def container=(container)
    @container = container
  end
  
  def receive_callback( aproc, selector = MessageSelector.match_everyone)
    m = @container.msg_pool(name)
    msg = nil
    m.access { |queue|
      msg = queue.retrieve(selector)
      if msg == nil or not selector.onetime
        queue.regist_selector(selector, aproc)
      end     
    }
    if msg != nil
      aproc.call(msg)
    end
  end

  def receive(selector = MessageSelector.match_everyone)    
    m = @container.msg_pool(name)
    msg = nil
    m.access { |queue|       
      msg = queue.retrieve(selector)
    }
    if msg != nil and block_given?
      yield msg
    end
    return msg    
  end


  def name
    @aid.name
  end

  def send_msg(msg)
    tc_set = Set.new
    msg['sender'] = @aid
    msg['receivers'].each { |aid|

      if aid.addresses.empty?
        @container.resolve_aid(aid)
      end
      tc_set << aid.container_address
    }

    #DRb.start_service()
    tc_set.each { |addr|
      if addr == @container.address
        # If the target is at the same container as the sender, then bypass druby remote call
        # using direct in memory messages
        @container.message(msg)                   
      else
        c = DRbObject.new(nil, "druby://#{addr}")   # Set up a druby call object over other containers
        c.message(msg)                            # call remote method
      end
    }
    #DRb.stop_service()
  end
    
  def behaviours 
    @behaviours
  end

  def add_behaviour(behaviour)
    behaviour.agent = self
    @behaviours << behaviour    
  end
  
  def setup
  end
  def teardown
  end
  
  def schedule
    @behaviours.each { |b|
      if not b.skip
        b.action
      end
    }
    while t = @container.msg_pool(name).receive_selected
      sel, pr, msg = t
      pr.call(msg)
    end
    sleep 0.005
  end

  def run
    #Start up behaviours
    @behaviours.each { |b|
      b.startup
    }
    # Schedule behaviours
    while true
      schedule
    end
  end

end

end


