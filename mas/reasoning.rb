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
    "fact(#{@name} #{l.join(" ")})"
  end
end

class NoSuchBindingError < Exception
end

class NotMatchException <Exception
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
    @str_args = args
    @incoming_args = Array.new
    @args = a2t(args).collect { |item| make_item(item)  }    
  end

  def incoming_args
    @incoming_args
  end

  def merge_incoming_dict(other, dm)
    ndm = Hash.new
    @incoming_args.zip(other.incoming_args).each { |x, y|
      if dm.has_key? y
        ndm[x] = dm[y]
      end
    }
    return ndm
  end

  def to_s
    l = @str_args.collect { |a| arg_to_s(a)}
    "pattern(#{@name} #{l.join(" ")})"
  end

  def name
    @name
  end
  def a_to_bt(a)
    
  end
  def search(engine, binding)
    
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
      @incoming_args << item[1, item.length]
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
          raise NoSuchBindingError.new("#{}")
        end
    else   # symbol #
      return arg[1]
    end     
  end

  def bind_pattern_unit(arg, dm)
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
          return arg
        end
    else   # symbol #
      return arg[1]
    end     
  end

  #
  # Bind a pattern to into a fact
  #
  def bind(dm)
    pa = false
    @incoming_args.each { |a|
      if not dm.include?(a)
        pa = true
        break
      end
    }
    if pa
      args = @args.collect { |a| bind_pattern_unit(a, dm)  }
      return Pattern.new(@name, *args)
    else
      args = @args.collect { |a| bind_unit(a, dm)  }
      return Fact.new(@name, args)
    end
  end

  def assert_match(expr, msg = "")
    if not expr
      raise NotMatchException.new(msg)
    end
  end

  def match_unit(p_word, f_word, dm)
    x = p_word[0]
    a = p_word[1]
    if x == '?'             #Variable
      if dm.has_key?(a)
        assert_match(dm[a] == f_word, "VARIABLE, #{a}:#{dm[a]} == #{f_word}")
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
    rescue NotMatchException => e
      #puts "================"
      #puts e
      #puts to_s
      #puts pre_dict
      #puts fact
      #puts "Not match"
      return nil
    end
    return dm
  end

  def search_fact(fact, ndw)
    #puts "MATCHING #{fact}"
    dt = match(fact, ndw)
    
    if dt
      ndw.update(dt)
      return true
    else
      return false
    end
  end
  
end  # End of class Pattern

class SearchPos
  def initialize(name, isfact = true, idx = 0, data = nil)
    @name = name
    @isfact = isfact
    @idx = idx
    @data = data
  end
  def name
    @name
  end
  def isfact
    @isfact
  end
  def idx
    @idx
  end

  def obj
    @data
  end

end

class RuleEngine
  def initialize(facts, rules, bw_rules = [])
    @facts_by_name = {}
    @d_fact_ids = Hash.new

    facts.each { |fact|
      if not @d_fact_ids.has_key? fact.guid
        do_add_fact(fact)
      end
    }    
    @rules = rules

    @bw_rules = Hash.new
    bw_rules.each { |bw_rule|
      if not @bw_rules.has_key?(bw_rule.target_name)
        @bw_rules[bw_rule.target_name] = Array.new
      end
      @bw_rules[bw_rule.target_name] << bw_rule
    }

    @new_facts = []
    @remove_facts = Set.new
  end

  def bw_rules(target_name)
    if @bw_rules.has_key? target_name
      @bw_rules[target_name]
    else
      []
    end
  end

  def next_search_pos(name, pos = nil)
    
    fs = facts(name) + bw_rules(name)    
    
    if pos == nil
      idx = 0
    else
      idx = pos.idx + 1   
    end

    obj = fs[idx]
    if obj == nil

      return nil
    elsif obj.instance_of? Fact
      return SearchPos.new(name, true, idx, obj)
    else
      return SearchPos.new(name, false, idx, obj)
    end
  end

  def search_pattern(pattern, dw, oldpos)
    pos = next_search_pos(pattern.name, oldpos)

    ndw = dw.clone
    while pos != nil
      
      t = false
      if pos.isfact
        t = pattern.search_fact(pos.obj, ndw)        

      else

        tndw = pos.obj.target.merge_incoming_dict(pattern, ndw)
        #puts "SEARCHING RULE #{pos.obj.target_name}, #{arg_to_s(tndw)}"
        t, xdw = search_bwrule_patterns(pos.obj.patterns, tndw)
        if t
          
          fndw = pattern.merge_incoming_dict(pos.obj.target, tndw)

          ndw.update(fndw)
          puts "Got #{arg_to_s(tndw)}, #{arg_to_s(xdw)}, #{pos.obj.target.bind(ndw)},"
        end
      end        
      if t
        return pos, ndw
      end
      pos = next_search_pos(pattern.name, pos)
    end
    return nil
  end
  
 
      

  def search_bwrule_patterns(patterns, dm)    
    i = 0
    pos = nil
    ops = []
    ndm = dm
    puts "Searching for #{patterns} #{arg_to_s(dm)}"
    while i < patterns.size and i >= 0
      p = patterns[i]
      puts "SP #{p.bind(ndm)} #{arg_to_s(ndm)} #{pos}"

      pos, ndm = search_pattern(p, ndm, pos)      

      if pos == nil
        pos, ndm = ops.pop
        puts "Popped #{pos.obj} #{ndm}"
        i -= 1
      else
        puts "Pushed #{ops.length}-- #{arg_to_s(ndm)}"
        ops << [pos, ndm]
        pos = nil
        i += 1
      end      
    end
    a = ops[-1][1]
    if i >= patterns.size
      
      puts "END Searching for #{patterns} #{arg_to_s(a)}, TRUE"
      if block_given?
        yield(a)
      end      
      return true, a
    else
      puts "END Searching for #{patterns} #{arg_to_s(a)}, FALSE"
      return false, a
    end
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
    if @facts_by_name.has_key? name
      @facts_by_name[name]
    else
      []
    end
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


class BW_Rule
  def initialize(name, patterns, target)
    @name = name
    @patterns = patterns
    @target = target
  end

  def target
    @target
  end

  def target_name
    @target.name
  end
  def patterns
    @patterns
  end
  def to_s
    "(defrule #{@name} #{@patterns} ==> #{@target})"
  end
end

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
    arg.each { |k, v| ls << "#{arg_to_s(k)}=>#{arg_to_s(v)}" }

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
  p1 = Pattern.new("parent", "?u", "?v")
  p2 = Pattern.new("parent", "?v", "?t")
  p3 = Pattern.new("grand-parent", "?u", "?t")

  f1 = Fact.new("parent", "Mike", "Jerry")
  f3 = Fact.new("parent", "Jerry", "tt")
  f2 = Fact.new("parent", "tt", "Pig")
  f4 = Fact.new("parent", "Jerry", "Juke")

  r1 = BW_Rule.new("grand-parent", [p1, p2], p3)

  p8 = Pattern.new("parent", "?w", "?x")
  p9 = Pattern.new("grand-parent", "?x", "?y")
  p10 = Pattern.new("gg-parent", "?w", "?y")
  
  r2 = BW_Rule.new("gg-parent", [p8, p9], p10)

  engine = RuleEngine.new([f1, f2, f3, f4], [], [r1, r2])


  p4 = Pattern.new("gg-parent", "?a", "?b")
  p5 = Pattern.new("main-test", "?a", "?b")
  
  #print engine.search_pattern(p4, {}, nil)
  #engine.search_bwrule_patterns([p4], {}) { |a|
  #  puts arg_to_s(a)
  #}


  #puts t, arg_to_s(dw)

  
end

test
  
