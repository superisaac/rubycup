require 'set'
#require 'utility'
module MAS
class ACLMessage
  @@attribute_names = 
        ["sender", "receivers",  "content", "language", "ontology", \
        "convention_id",  "reply-with", "in-reply-to", "reply-by"]  
  @@next_guid = 1

  def initialize(performative, attrs = {})        
    @performative = performative.upcase              
    @attributes = { "receivers"=> Set.new([])}
    @guid = @@next_guid
    @@next_guid += 1
    attrs.each { |k, v|
      set_attr(k, v)
    }
  end
  
      
  def guid
    @guid
  end
  def gen_reply(perf, reply_aid)
    reply = ACLMessage.new(perf, attrs={ "sender" => reply_aid,
                     "ontology" => self['ontology'],
                     "language" => self['language'],
                   })

    if self['reply-with']
      reply['in-reply-to'] = self['reply-with']
    end
    reply['receivers'] << self['sender']
    return reply
  end

  def addreceivers(areceiver)
    @receivers << areceiver
  end

  def performative
    @performative
  end

  def performative=(ap)
    @performative = ap.upcase
  end

  def [](k)
    @attributes[k]
  end    

  def []=(k, v)
    set_attr(k, v)
  end

  def set_attr(k, v)
    k = k.downcase
    if @@attribute_names.member?(k)
      
      @attributes[k] = v
    end
  end 

  def to_s
    s = "(#{@performative}"

    @@attribute_names.each { |k|
      v = attr_to_s(k)

      if v
        s += "\n\t" + v 
      end
    }      

    s += ")"
    s
  end
    
private
  def attr_value_to_s(v)
    if v.instance_of? Array

      return "(sequence #{v.join(" ")})"
    elsif v.instance_of? Set

      return "(set #{v.to_a.join(" ")})"  
    elsif v.instance_of? ACLStruct

      return v.to_s
    elsif v.instance_of? String

      if v =~ /[():\s]/

        return "\"#{v}\""
      else
        return v
      end
    else
      return v.to_s
    end
  end

  def attr_to_s(k)
    a = @attributes[k]

    if a != nil      
      v = attr_value_to_s(a)
      return ":#{k} #{v}" 
    else
      return nil
    end      
  end
end

class ACLMessage
   # ACL Performative Constants
    def ACLMessage.ACCEPT_PROPOSAL; "ACCEPT_PROPOSAL";  end
    def ACLMessage.AGREE; "AGREE" ;  end
    def ACLMessage.CANCEL; "CANCEL";  end
    def ACLMessage.CFP; "CFP";  end
    def ACLMessage.CONFIRM; "CONFIRM";  end
    def ACLMessage.DISCONFIRM; "DISCONFIRM";  end
    def ACLMessage.INFORM; "INFORM";  end
    def ACLMessage.INFORM_IF; "INFORM_IF";  end
    def ACLMessage.INFORM_REF; "INFORM_REF";  end
    def ACLMessage.NOT_UNDERSTOOD; "NOT_UNDERSTOOD";  end
    def ACLMessage.PROPAGATE; "PROPAGATE";  end
    def ACLMessage.PROPOSE; "PROPOSE";  end
    def ACLMessage.PROXY; "PROXY";  end
    def ACLMessage.QUERY_IF; "QUERY_IF";  end
    def ACLMessage.QUERY_REF; "QUERY_REF";  end
    def ACLMessage.REFUSE; "REFUSE";  end
    def ACLMessage.REJECT_PROPOSAL; "REJECT_PROPOSAL";  end
    def ACLMessage.REQUEST; "REQUEST";  end
    def ACLMessage.REQUEST_WHEN; "";  end
    def ACLMessage.REQUEST_WHENEVER; "REQUEST_WHENEVER";  end
    def ACLMessage.SUBSCRIBE; "SUBSCRIBE";  end
    def ACLMessage.UNKOWN; "UNKOWN";  end
end

class ACLMessage 
  # Parse The string representation into ACLMessage object  
  def ACLMessage.parse(sc)
    a = Utility.parse sc
    if a
      msg = ACLMessage.new a.head
      a.pair.each { |t|
        k, v = t
        msg[k] = v
      }
      msg
    else
      nil
    end
  end  
  
end

class ACLMessage
  def ACLMessage.new_id
    "#{(rand * 900000000 + 100000000).to_i}"
  end
end


class MessageSelector
  def and(o)
    and_proc = proc { |msg|
      return match(msg) && o.match(msg)
    }
    MessageSelector.new(and_proc, onetime && o.onetime)
  end
  
  def or(o)
    or_proc = proc { |msg|
      return match(msg) || o.match(msg)
    }
    MessageSelector.new(or_proc, onetime || o.onetime)
  end

  def initialize(match_proc, onetime = true)
    @match_proc = match_proc
    @onetime = onetime
  end

  def onetime
    @onetime
  end

  def match(msg)
    return @match_proc.call(msg)
  end
    
  def MessageSelector.match_performative(perf, onetime=true)
    return MessageSelector.new(proc { |msg|    

                         return perf == (msg.performative) 
                       }, onetime)
  end
  def MessageSelector.match_inreplyto(repyid, onetime=true)
    return MessageSelector.new(proc { |msg|    
                         return repyid == (msg['in-reply-to']) 
                       }, onetime)
  end

  def MessageSelector.match_ontology(onto, onetime=true)
    return MessageSelector.new(proc { |msg|    
                         return onto == (msg['ontology']) 
                       }, onetime)
  end

  def MessageSelector.match_everyone
    return MessageSelector.new(proc { |msg|                         
                         return true
                       })
  end

end




def test
  a = ACLMessage.parse('(abc :sender (agent-identifier :name "httpreceivers. com"))')
  a['receivers'] << 6
  print a.to_s
end

end



