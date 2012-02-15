require 'set'
module MAS
class AID   
   def initialize(name, *resolvers)
    @name = name
    @addresses = Set.new []
    @resolvers = Set.new resolvers   
   end

   def container_address
     if @addresses.size <= 0
       return nil
     else

       t = AID.parse_address(@addresses.to_a[0])
       return "#{t[1]}:#{t[2]}"
     end
   end
       
   def addresses
     @addresses
   end

   def name
     @name
   end
   def resolvers
     @resolvers
   end   

   # Return the 4 parts of name: (local_name, host, port, location)
   def AID.parse_address(addr)
     if addr =~ /([^@]+)(@([\w.%]+)(\:(\d+))?)?/
       return  $1, $3, $5
     end
     return nil
   end
  
   def to_s 
      s = "(agent-identifier :name #{@name}"
      if @addresses.size > 0
        s += " :addresses #{@addresses}"
      end  
     if @resolvers.size > 0
        s += " :resolvers #{@resolvers}"
      end     
      s += ")"
      s
    end
end

def test
  a = AID.new "tt123@l2ocalhost:8000/hig"
  a.addresses << "abc@localhost" << "addb@localhsot"
  puts  a.name
end

end
