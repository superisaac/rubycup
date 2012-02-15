
require 'set'
require 'drb'
#require "aclmessage"
module MAS
  class MessageQueue
    def initialize(name)
      @name = name
      @mutex = Mutex.new
      @array = Array.new
      @selectors = Array.new
      @selected_msgs = Queue.new
    end

    def access
      @mutex.synchronize do
        yield self
      end
    end

    def receive_selected
      if @selected_msgs.empty?
        return nil
      else
        @selected_msgs.pop(true)
      end
    end

    def regist_selector(selector, pr)

      @selectors << [selector, pr]        
    end

    def <<(msg)
      aproc  = nil
      t = nil
      access{ |q|
        @selectors.each { |selector, pr|
          if selector.match(msg)
            aproc = pr
            @selected_msgs << [selector, pr, msg]
            if selector.onetime
              @selectors.delete([selector, pr])
            end
            break
          end        
        }      
        if aproc == nil
          return @array << msg
        end
      }
    
    end
    def retrieve(selector)
      a = nil
      @array.each { |msg|
        if a == nil and selector.match(msg)
          a = msg
          break
        end
      }
      @array.delete a
      return a
    end
  end
  
  class Container
    def initialize(name, addr, root_addr)
      @name = name    
      @addr = addr
      @root_addr = root_addr
      @agents = Hash.new    
      @msgs = Hash.new
      @cache_addr = Hash.new
      @running = Array.new
    end
    
    def platform
      return  DRbObject.new(nil, "druby://#{@root_addr}")
    end

    def msg_pool(name)
      if @msgs.has_key? name
        return @msgs[name]
      else
        @msgs[name] = MessageQueue.new name
      end
    end

    def address
      @addr
    end

    def add_agent(agent)    
      ap = platform
      if ap.register_ns(agent.name, address)
        @agents[agent.name] = agent
        
        @running << Thread.new(agent) { |agent|
          sleep 1
          agent.setup
          agent.run
        }      
      end  
    end

    def resolve_aid(aid)    
      #aid.addresses << "#{aid.name}@#{address}"  

      if @cache_addr.has_key? aid.name
        addr = @cache_addr[aid.name]
      else
        ap = platform
        addr = ap.resolve_ns(aid.name)
        @cache_addr[aid.name] = addr
      end
      
      aid.addresses << "#{aid.name}@#{addr}"   
    end
    
    def add_agent_class(name, agent_class)
      agent = agent_class.new(name, self)
      add_agent(agent)
    end

    #
    # Remote message 
    #
    def message(msg)
      msg['receivers'].each {|recv_aid|
        if @addr == recv_aid.container_address
          aid_name = recv_aid.name
          msg_pool(aid_name) << msg 
        end
      }
    end

    def start_service(root_address = nil)
      if root_address
        @root_address = root_address
      else
        @root_address = address
      end
    
      puts "Container #{@name} runs at druby://#{@addr}"

      DRb.start_service("druby://#{@addr}", self)        
      sleep 1 
      yield(self) # Initial works
      @thread_id = DRb.thread
    end
    def stop_service
      Thread.kill(@thread_id)
    end
  end


  class Platform < Container
    def initialize(name, addr)
      super(name, addr, addr)    
      @resolve_table = Hash.new
    end

    def register_ns(name, container_address)
      if @resolve_table.has_key? name
        return false      
      end
      @resolve_table[name] = container_address      
      return true
    end
    
    def resolve_ns(name)
      @resolve_table[name]
    end

    def bootstrap
      add_agent_class("ams",Agent)
    end  
  end
end

