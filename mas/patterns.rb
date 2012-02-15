
module MAS
  #
  # ContractNet Mixins
  # There are two actors: Initiator and Responder
  #
  module ContractNetInitiator
    #
    # functions that need to implemented: cfp_<ontology> , cfpeval_<ontology>
    #
    def initiate_cfp(language, ontology, responders)
      cfp_content = eval("cn_cfp_#{ontology}()")
      
      eval_buffer = []
      responders.each { |aid_tn|    
        
        msg = ACLMessage.new(ACLMessage.CFP, {
                               "language" => language,
                               "ontology" =>  ontology,
                               "reply-with" => ACLMessage.new_id,
                             })
        msg['receivers'] << aid_tn
        msg['content'] = cfp_content    
        ps = proc { |msg|
          eval_buffer << [aid_tn, msg['content']]            
          if eval_buffer.size == responders.size
            eval("cn_cfpeval_#{ontology}(*eval_buffer)")
          end
        }    
        @agent.send_msg(msg)  
        @agent.receive_callback(ps, MessageSelector.match_inreplyto(msg['reply-with']))
      }
    end
  end

  module ContractNetResponder
    #
    # functions that need to implemented: propose_<ontology>
    #
    def install_cn_responder(ontology)
      eval_ps = proc { |msg|        
        propose = eval("cn_propose_#{ontology}(msg['content'])")
        msg = msg.gen_reply(ACLMessage.PROPOSE, @agent.aid)
        msg['content'] = propose
        @agent.send_msg(msg)
      }
      @agent.receive_callback(eval_ps, MessageSelector.match_performative(ACLMessage.CFP, false))
    end
  end
end
