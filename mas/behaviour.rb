#require 'agent'
module MAS
class Behaviour
  def agent
    @agent
  end
  def agent=(agent)
    @agent = agent
  end
  def action
  end
  def startup
  end

  def skip
    false
  end
end

class OneShutBehaviour < Behaviour
  def initialize
    @state = 0
  end
  def skip
    if @state >= 2
      return true
    else
      return false
    end
  end
  def oneshut
  end
  def action
    @state += 1
    oneshut
  end
end

class CyclicBehaviour < Behaviour
  def initialize(intervel)
    @intervel = intervel    
  end
  def startup
    @old_tm = Time.now    
  end

  def skip    
    t = Time.now 
    if t - @old_tm >= @intervel
      @old_tm = t     
      return  false
    else
      return true
    end
  end
end


end
def test
  a = MAS::Agent.new "abc"

  a.add_behaviour(MAS::OneShutBehaviour.new)

  Thread.abort_on_exception = true
  t = Thread.new(a){ |a|
    a.run
  }

  t.join
end

if __FILE__ == $0
  test
end

