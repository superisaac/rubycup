require "mas/mas"
require 'drb'

include MAS
class ObserverDrbBehaviour < Behaviour
  def register_observer
     msg = ACLMessage.new(ACLMessage.REQUEST, {
                           "sender" => @aid,
                           "language" => "English",
                           "ontology" => "register.observer",
                           "reply-with" => "ppp"
                         })
    msg['receivers'] << AID.new("Match")
    #puts __FILE__, msg
    @agent.send_msg(msg)
  end

  def startup    
    register_observer   
    @agent.setup_drb
  end

 def action
   msg = @agent.receive( MessageSelector.match_performative(ACLMessage.INFORM))
   if msg
     #puts "------------"
     #puts __FILE__, msg
     #puts msg     
     @agent.snap = msg['content']
   end
 end
end

class ObserverDRbAgent < Agent
  def snap=(snap)
    #
    # Set the snapshut 
    #
    @snap = snap
  end

  def snap
    #
    # A DRb object method
    #
    @snap
  end

  def setup_drb
    #
    # Set up a snapshut of the match and get the DRb thread
    # 
    DRb.start_service('druby://localhost:8779', self)    
    @t = DRb.thread
  end

  def setup
    @snap = nil
    add_behaviour(ObserverDrbBehaviour.new)
  end
end
