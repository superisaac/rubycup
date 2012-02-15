require 'set'
#require 'aid'
module MAS
class ACLStruct
  def initialize(head)
    @head = head

    @pair = Hash.new 
  end

  def head
    @head
  end

  def pair
    @pair
  end
  def to_s
    "(#{@head} #{@pair})"
  end
end

class Utility
  def Utility.acl_lex_pattern
    Regexp.new(/"[^"]*?"|\)|\(|\:\w+|[^\s()]+/) 
  end

  def Utility.acl_parse_word(t, tokens)
    if t == '('
      t = tokens.pop.downcase
      if t == 'sequence'        
        a = Array.new
      elsif t == 'set'
        a = Set.new
      else
        tokens.push t
        tokens.push "("
        v = acl_parse(tokens)
        if t == 'agent-identifier'
          v = parse_aid_from_acl(v)
        end
        return v
      end
      t = tokens.pop
      
      while t != ')'
        a << t
        t = tokens.pop
      end
      return a
    elsif t[0,1] == '"' and t[-1, 1] == '"'
      return t[1, (t.length - 2)]
    else
      return t
    end
  end

  def Utility.acl_parse_attr(t, tokens)

    if t[0,1] == ':'
      k = t[1, t.length]
      v = tokens.pop

      if v == ')'
        tokens.push v
        return k, nil
      else
        v = acl_parse_word(v, tokens)

        return k, v
      end        
    end
    return nil
  end  

  def Utility.parse(sc)
    tokens = sc.scan(acl_lex_pattern)
    tokens = tokens.reverse
    return acl_parse(tokens)
  end

  def Utility.acl_parse(tokens)    
    t = tokens.pop
    if t == '('      
      a = ACLStruct.new(tokens.pop)
      t = tokens.pop      
      while t != ")"

        k, v = acl_parse_attr(t, tokens)  

        if k
          a.pair[k] =  v
        end
        t = tokens.pop
      end
      return a
    else
      return nil
    end
  end
  def Utility.parse_aid_from_acl(acl_struct)
     aid = AID.new(acl_struct.pair["name"])
     acl_struct.pair.each { |k, v|
       if k == 'addresses'
         v.each {|c|
           aid.addresses << c
         }
       elsif k == 'resolvers'
         v.each {|c|
           aid.resolvers << c
         }
       end
     }
     aid
   end
end
end
