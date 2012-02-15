require 'set'

class Fact
  def initialize(name, *args)
    @name = name
    @args = a2t(args)
    @guid = nil
  end

  def guid
    if @guid == nil
      @guid = to_s.downcase
    end
    @guid
  end

  def name
    @name
  end
  def args
    @args
  end

  def to_s
    l = @args.collect { |a| arg_to_s(a)}
    "(#{@name} #{l.join(" ")})"
  end
end

class NoSuchBindingError < Exception
end

class NotMatchExceptin <Exception
end

def merge_dict(dma, dmb)
  sa, sb = Set.new(dma.keys), Set.new(dmb.keys)
  s = sa.intersection(sb)
  ta, tb  = sa - s, sb - s
  dm = {}
  s.each { |k|
    if dma[k] != dmb[k]
      return nil
    else
      dm[k] = dma[k]
    end
  }
  ta.each { |k| dm[k] = dma[k] }
  tb.each { |k| dm[k] = dmb[k] }
  dm
end

class Pattern
  def initialize(name, *args)
    @name = name
    @args = a2t(args).collect { |item| make_item(item)  }
  end

  def name
    @name
  end
  def a_to_bt(a)
    
  end

  def make_item(item)
    if item.instance_of? Symbol
      item = item.to_s
    end

    if item.instance_of? Array
      #
      # A tree-like array
      #
      if item.size == 1
        return ["e", make_item(item[0])]
      else   # two element list
        return ["l", make_item(item[0]), make_item(item[1])]
      end
    elsif item[0,1] == '?'
      return ["?", item[1, item.length]]
    else
      return ["#", item]
    end
  end

  #
  # Bind a single argument of a pattern
  #
  def bind_unit(arg, dm)
    t = arg[0]
    if t == "l":           # binary node
        return [bind_unit(arg[1], dm), bind_unit(arg[2], dm)]
    elsif t == 'e':        # Single node
        return [bind_unit(arg[1], dm)]
    elsif t == '?':        # unbounded variable
        s = arg[1]
        if dm.has_key? s
          return dm[s]
        else
          raise NoSuchBindingError
        end
    else   # symbol #
      return arg[1]
    end     
  end

  #
  # Bind a pattern to into a fact
  #
  def bind(dm)
    args = @args.collect { |a| bind_unit(a, dm)  }
    return Fact.new(@name, args)
  end

  def assert_match(expr)
    if not expr
      raise NotMatchException.new
    end
  end

  def match_unit(p_word, f_word, dm)
    x = p_word[0]
    a = p_word[1]
    if x == '?'             #Variable
      if dm.has_key?(a)
        assert_match(dm[a] == f_word)
      else
        dm[a] = t2a(f_word)
      end
    elsif x == 'l'
      assert_match(f_word.instance_of?(Array))
      b = p_word[2]
      assert_match(f_word.length >= 1)
      match_unit(a, f_word[0], dm)
      if f_word.length >= 2
        match_unit(b, f_word[1], dm)
      else
        match_unit(b, [], dm)
      end      
    elsif x == 'e'
      assert_match(f_word.instance_of?(Array))
      match_unit(a, f_word, dm)
    else
      assert_match(a == f_word)
    end
  end

  def match_engine(afacts)
    bindings = []
    afacts.each { |f|      

      dm = match(f)
      if dm
          bindings << [f, dm]
      end
    }
    return bindings
  end

  def match(fact, pre_dict= {})
    if fact.name != @name or @args.length != fact.args.length
      return nil
    end
    dm = pre_dict.clone

    begin
      @args.zip(fact.args).each { |p_word, f_word|
        match_unit(p_word, f_word, dm)          
      }
    rescue NotMatchException
      puts "Not match"
      return nil
    end
    return dm
  end

end  # End of class Pattern


class RuleEngine
  def initialize(facts, rules)
    @facts_by_name = {}
    @d_fact_ids = Hash.new

    facts.each { |fact|
      if not @d_fact_ids.has_key? fact.guid
        do_add_fact(fact)
      end
    }    
    @rules = rules
    @new_facts = []
    @remove_facts = Set.new
  end

  def all_facts
    res = Array.new
    @facts_by_name.each_value { |vs|
      vs.each {  |fact|
        res << fact
      }
    }
    res
  end
  def facts(name)
    @facts_by_name[name]
  end  

  def produce
    new_facts = []
    @rules.each { |rule|
      new_facts += rule.produce(self)
    }
    new_facts
  end

  def add_fact(fact)
    if not @d_fact_ids.has_key? fact.guid
      @new_facts << fact
    end
  end

  def do_add_fact(fact)
    vs = @facts_by_name[fact.name] 
    if not vs   
      @facts_by_name[fact.name] = Array.new
    end
    @facts_by_name[fact.name] << fact
    @d_fact_ids[fact.guid] = fact
  end
  
  def do_delete_fact(fact)
    fact = @d_fact_ids.delete(fact.guid)
    vs =  @facts_by_name[fact.name]
    if vs
      vs.delete(fact)
    end
  end
  def remove_fact(fact)
    fact = @d_fact_ids[fact.guid]
    if fact
      @remove_facts << fact
    end
  end

  def update    
    @rules.each { |rule|  rule.update(@new_facts, @remove_facts)   }    
    #
    # Remove facts
    #
    @remove_facts.each { |fact|
        do_delete_fact(fact)    
    }   
    #
    # Add facts
    #
    @new_facts.each { |fact|
      do_add_fact(fact)
      #@facts << fact
      #@d_fact_ids[fact.guid] = fact
    } 

    @new_facts = []
    @remove_facts = Set.new
  end
  def rollback
    @new_facts = []
    @remove_facts = Set.new
  end
  
end

class AlphaNode
  def initialize(pattern, bindings)
    @pattern = pattern
    @bindings = bindings    
    @new_bindings = []
  end

  def update
    @bindings += @new_bindings
    @new_bindings = []
  end

  def merge(a_node)
    results = []
    @bindings.each { |fact_a, dm_a|
      a_node.bindings.each { | fact_b, dm_b | 
        dm = merge_dict(dm_a, dm_b)
        if dm
          results << [[fact_a, fact_b], dm]
        end
      }
    }
    return BetaNode.new(results)
  end

  def merge_new_binding(a_node, b_node)
    results = []
    
    @bindings.each { | fact_a, dm_a |
      a_node.new_bindings.each { | fact_b, dm_b|
        dm = merge_dict(dm_a, dm_b)
        if dm
          results << [[fact_a, fact_b], dm]
        end
      }
    }
    @new_bindings.each { | fact_a, dm_a |
      a_node.bindings.each { | fact_b, dm_b|
        dm = merge_dict(dm_a, dm_b)
        if dm
          results << [[fact_a, fact_b], dm]
        end
      }
    }    
    @new_bindings.each { | fact_a, dm_a |
      a_node.new_bindings.each { | fact_b, dm_b|
        dm = merge_dict(dm_a, dm_b)
        if dm
          results << [[fact_a, fact_b], dm]
        end
      }
    }
    b_node.assert_bindings(results)
  end
  def bindings
    @bindings
  end

  def new_bindings
    @new_bindings
  end
  def remove_facts(set_remove_factids)
    @bindings = @bindings.collect { |fact, dm|
      if set_remove_factids.include? fact.guid
        nil
      else
        [fact, dm]
      end
    }.compact   
  end
    
  def assert_bindings(new_bindings)
    @new_bindings = new_bindings
  end

  def get_binding
    @bindings.collect {|e| e[1]}
  end
end  # End of class AlphaNode

class BetaNode
  def initialize(bindings)
    @bindings = bindings
    @new_bindings = []
  end
  def update
    @bindings += @new_bindings
    @new_bindings = []
  end

  def merge(a_node)
    results = []
    bindings.each { |facts_a, dm_a|       
      a_node.bindings.each { | fact_b, dm_b | 
        dm = merge_dict(dm_a, dm_b)
        if dm
          results << [facts_a + [fact_b], dm]
        end
      }
    }
  end

  def remove_facts(set_remove_factids)
    @bindings = @bindings.collect { |facts, dm|
      set_factid = Set.new(facts.collect {|f| f.guid})
      if set_remove_factids.intersection(set_factid).size > 0 
        nil
      else
        [facts, dm]
      end
    }.compact   
  end

  def merge_new_binding(a_node, b_node)
    results = []
    @new_bindings.each { | facts_a, dm_a |
      a_node.bindings.each { | facts_b, dm_b|
        dm = merge_dict(dm_a, dm_b)
        if dm
          results << [facts_a + [fact_b], dm]
        end
      }
    }
    @bindings.each { | facts_a, dm_a |
      a_node.new_bindings.each { | facts_b, dm_b|
        dm = merge_dict(dm_a, dm_b)
        if dm
          results << [facts_a + [fact_b], dm]
        end
      }
    }
    @new_bindings.each { | facts_a, dm_a |
      a_node.new_bindings.each { | facts_b, dm_b|
        dm = merge_dict(dm_a, dm_b)
        if dm
          results << [facts_a + [fact_b], dm]
        end
      }
    }
    b_node.assert_bindings(results)
  end

  def get_binding
    @bindings.collect {|e| e[1]}
  end

  def new_bindings
    @new_bindings
  end

  def assert_bindings(new_bindings)
    @new_bindings = new_bindings
  end
end  # End of class BetaNode



class Rule
  def initialize(name, patterns, results)
    @name = name
    @patterns = patterns
    @results = results
  end

  def bind
    facts = []
    get_binding.each{ |dbinding|
      @results.each { |res|
        f  = res.bind(dbinding)
        if f
          facts << f
        end
      }
    }
    return facts
  end

  def update(new_facts, remove_facts)
    set_remove_factids = Set.new(remove_facts.collect {|f| f.guid})
    @a_nodes.each { |a_node| a_node.remove_facts(set_remove_factids) }
    @b_nodes.each { |b_node| b_node.remove_facts(set_remove_factids) }


    @a_nodes.zip(@patterns).each { |a_node, p|
      new_bindings = p.match_engine(new_facts)
      a_node.assert_bindings(new_bindings)
    }
    tnode = @a_nodes[0]

    @b_nodes.zip(@a_nodes[1..-1]).each { |b_node, a_node|

      tnode.merge_new_binding(a_node, b_node)
      tnode.update
      a_node.update
      t_node = b_node
    }
    tnode.update
  end
  

  def produce(engine)
    #
    # Produce alpha nodes
    #
    @a_nodes = []
    @patterns.each { |p|
      bindings = p.match_engine(engine.facts(p.name))
      @a_nodes << AlphaNode.new(p.name, bindings)
    }
    #
    # Produce beta nodes
    #
    @b_nodes = []
    @tnode = @a_nodes[0]
    @a_nodes[1..-1].each { |anode|
      @tnode = @tnode.merge(anode)
      @b_nodes << @tnode
    }
    return bind

  end   #End of method produce

  def get_binding
    if @tnode
      return @tnode.get_binding
    end
  end    
end   # End of class Rule

def arg_to_s(arg)
  if arg.instance_of? Array
    varg = arg.collect { |a| arg_to_s(a)}
    return "[#{varg.join(", ")}]"
  elsif arg.instance_of? Hash
    ls  = Array.new
    arg.each { |k, v| ls << "#{arg_to_s(k)}==>#{arg_to_s(v)}" }

    return "{#{ls.join(", ")}}"
  elsif arg.instance_of? String
    if arg =~ /'\s/
      return "\"#{arg}\""        
    end
  end 
  return arg.to_s
end

def a2t_elem(e)
  if e.instance_of? Array
    return a2t(e)
  else
    return e
  end    
end

def a2t(a)
  if not a.instance_of? Array
    return a
  elsif a.size == 0
    return []
  elsif a.size == 1
    return a2t_elem(a[0])
  else 
    return [a2t_elem(a[0]), a2t(a[1, a.length])]
  end
end

def t2a(t)
  if t.instance_of? Array
    l = Array.new
    if t.size >= 2
      l << t2a(t[0])
      if t[1].instance_of? Array
        l += t2a(t[1])
      else
        l << t2a(t[1])
      end
    elsif t.size == 1
      l << t2a(t[0])      
    end
    return l
  else
    return t
  end      
end


def test
  p1 = Pattern.new("parent", "?a", "?x")
  p2 = Pattern.new("parent", "?x", "?y")
  p3 = Pattern.new("grand-parent", "?a", "?y")

  r1 = Rule.new("grand-parent", [p1, p2], [p3])

  f1 = Fact.new("parent", "Mike", "Jerry")
  f3 = Fact.new("parent", "Jerry", "tt")
  f2 = Fact.new("parent", "Jerry", "Pig")
  f4 = Fact.new("parent", "Jerry", "Pig")

  engine = RuleEngine.new([f1, f2, f3, f4], [r1])

  fs = engine.produce()
  
  fs.each { |f|
    #engine.add_fact(f)    
  }
  engine.update
  puts '----------'

  engine.remove_fact(Fact.new("parent", "Jerry", "Pig"))


  fs = engine.produce
  fs.each { |f|
    engine.add_fact(f)    
  }
  engine.update
  puts '-------------'
  puts engine.all_facts
end

test
  
