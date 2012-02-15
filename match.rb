require "mas/mas" # require source of mas
require 'vct'
require "config"

include MAS   # import MAS namespace


class BallInfo
  attr_reader :pos, :v

  def initialize(pos , v)
    @pos = pos    
    @v = v
    @attach = nil
  end

  def attach=(player)
    @attach = player
  end
  def attached_on?(player)
    @attach == player
  end

  def free?
    return @attach == nil
  end
  
  def release(d1, d2)
    @attach = nil
    @v = (d1.velocity + d2.velocity).normalize(Config.ball_speed) 
  end

  def velocity=(v)
    @v = v.normalize(Config.ball_speed)
  end

  def info
    holder = "none"
    if @attach
      holder = @attach.title
    end
    return [holder, @pos.x, @pos.y, @v.direction]
  end

  def hold_by(player)
    @attach = player
  end

  def test_hit_wall(w, h)
    r = Config.player_radius
    if @pos.x <= r 
      if @pos.y > h * 0.4  and @pos.y < h *0.6
        # team  b got a score
        return 5         
      else
        return 1
      end
    elsif  @pos.x >= w - r 
      if @pos.y > h * 0.4 and @pos.y < h *0.6
        # team agot a score
        return 6         
      else
        return 3
      end
    elsif @pos.y <= r 
      return 2
    elsif @pos.y >= h - r
      return 4
    else
      return 0
    end
  end
  

  @@wall_md = [0.5 * PI, PI, 1.5 * PI, 0]

  def bounce_wall(wall)
    r = Config.ball_radius
    w = Config.ground_width
    h = Config.ground_height

    if wall >= 1 and wall <=4 
      @v = @v.mirror(@@wall_md[wall - 1])    
      case wall
      when 1
        @pos = Vct.new(r + r - @pos.x, @pos.y)     
      when 2 
        @pos = Vct.new(@pos.x, r + r - @pos.y)
      when 3
        @pos = Vct.new((w - r) *2 - @pos.x, @pos.y)   
      when 4
        @pos = Vct.new(@pos.x, 2*(h - r) - @pos.y)
      end         
    end   
  end


  def step(s = 1.0)
    if free?
      @pos = @v * s + @pos
    else      
      @pos = @attach.ball_pos
      @v = @attach.velocity
    end
  end
end

class PlayerInfo

  attr_reader :title

  def initialize(title, pos, v)
    @title = title
    @v = v
    @pos = pos
  end

  def info
    return [@title, @pos.x, @pos.y, @v.direction]
  end
  def ball_pos
    #@pos + @v * (Config.player_radius + Config.ball_radius)
    @pos
  end
  def position
    @pos
  end
  #
  # Changable variables: velocity
  #
  def velocity
    @v
  end
  def velocity=(v)
    @v = v.normalize(Config.player_speed)
  end

  def step(s = 1.0)
    @pos = @v * s + @pos
  end
  
  def collision?(other)
    (other.position - @pos).abs <=  Config.player_radius + Config.player_radius
  end
  
  def collision_ball?(ball)
    (ball.pos - @pos).abs <= Config.player_radius + Config.ball_radius
  end

  def test_hit_wall(w, h)
    r = Config.player_radius
    if @pos.x <= r 
      return 1
    elsif  @pos.x >= w - r 
      return 3
    elsif @pos.y <= r 
      return 2
    elsif @pos.y >= h - r
      return 4
    else
      return 0
    end
  end
  
  def bounce(other)
    tv = @v
    @v = other.velocity
    other.velocity = tv
    step 6
  end 
  @@wall_md = [0.5 * PI, PI, 1.5 * PI, 0]

  def bounce_wall(wall)
    if wall >= 1 and wall <=4 

      @v = @v.mirror(@@wall_md[wall - 1])      

      r = Config.player_radius
      w = Config.ground_width
      h = Config.ground_height
    
      case wall
      when 1
        @pos = Vct.new(r + r - @pos.x, @pos.y)
      when 2
        @pos = Vct.new(@pos.x, r + r - @pos.y)
      when 3
        @pos = Vct.new((w - r) *2 - @pos.x, @pos.y)
      when 4
        @pos = Vct.new(@pos.x, 2*(h - r) - @pos.y)
      end      
    end
  end
end

class MatchBehaviour < CyclicBehaviour
  def initialize
    super(0.06)
    @tm = 0
  end

  def action
    @agent.step
    msg = ACLMessage.new(ACLMessage.INFORM, {
                           "sender" => @aid,
                           "language" => "football.term",
                           "ontology" => "Broadcast",
                           "reply-with" => "ppp"
                         })
    msg['receivers'] = @agent.observers
    msg['content'] = @agent.make_info_content(@tm)
    @tm += 1

    @agent.send_msg(msg)
  end
end

class ObserverRegisterBehaviour < Behaviour
  def startup
    ps = proc {|msg|
      @agent.add_observer(msg['sender'])
    }
    @agent.receive_callback(ps, MessageSelector.match_ontology("register.observer", false))
  end
end

class PlayerChangeBehaviour < Behaviour
  def startup
    ps = proc {|msg|
      @agent.change_velocity(msg['sender'].name, *msg['content'])
    }
    @agent.receive_callback(ps, MessageSelector.match_ontology("change.velocity", false))

    ps = proc {|msg|
      @agent.release_ball(msg['sender'].name, *msg['content'])
    }
    @agent.receive_callback(ps, MessageSelector.match_ontology("release.ball", false))
  end
end


class Snapshot
  attr_reader :tm, :score_a, :score_b, :ball_info, :players_info
  attr_writer :score_a, :score_b
  #
  # initialization
  #
  def initialize(tm, score_a, score_b, ball_info, players_info)
    @tm = tm
    @score_a = score_a
    @score_b = score_b
    @ball_info = ball_info
    @players_info = players_info
  end
 
  #
  # To a list of string representation of each field element.
  # 
  def to_a1
    l = ["#{@tm}"]
    l << ("#{@score_a}")
    l << "#{@score_b}"
    @ball_info.each{ |t|
      l << "#{t}"
    }    
    @players_info.each { |player|
      player.each { |t|
        l << "#{t}"        
      }
    }
    l
  end
  #
  # Turns the snapshut into a list of the format 
  # [timestamp, score of team a, score of team b, info of ball, info of players ...]
  #     it is used in the broadcasting to observers
  #
  def to_a    
    l = [@tm, @score_a,  @score_b, @ball_info]
    l += players_info
    l
  end
  #
  # String representation of Snapshut, used only in console output now
  # 
  def to_s
    "(#{to_a1.join(" ")})"
  end
end


class MatchAgent < Agent

  def make_info_content(tm)
    linfo = []
    (@teama + @teamb).each { |player|
      linfo << player.info
    }
    
    a = Snapshot.new(tm, @score_a, @score_b, @ball.info, linfo)
    a.to_a
  end
  def add_observer(observer_aid)
    @observers << observer_aid
  end
  def observers
    return Set.new(@player_aids.to_a + @observers.to_a)
    #return @observers
  end

  def update_score(bw)
    if bw == 5
      @score_b += 1
    elsif bw == 6
      @score_a += 1
    end
  end

  def step 

    @ball.step
    @players.each {|p|
      p.step
    }

    @players.size.times { |n|
      (n+1.. @players.size - 1).each { |m|
      #@players.size.times { |m|
  
        if @players[n].collision?(@players[m])
          @players[n].bounce(@players[m])

          if @ball.attached_on?(@players[n]) or @ball.attached_on?(@players[m])
            @ball.release(@players[n], @players[m]) 
            
            @ball.step(2)
          end
        end        
      }
      a = @players[n].test_hit_wall(@width, @height)
      @players[n].bounce_wall(a)
      
      if @ball.free? and @players[n].collision_ball?(@ball)
        @ball.hold_by(@players[n])
      end
    }


    if @ball.free?
      bw = @ball.test_hit_wall(@width, @height)
      update_score(bw)
      @ball.bounce_wall(bw)   

      if bw == 5 
        _, tp = @teama.map{|t| [t.position.x, t]}.min
        @ball.attach = tp       
      elsif bw == 6
        _, tp = @teamb.map{|t| [t.position.x, t]}.max
        @ball.attach = tp
      end        
    end
  end
 
  def change_velocity(name, v)
    

    p = @player_dict[name]
    if p
      p.velocity = Vct.new_dr(v, Config.player_speed)
    end
  end
  
  def release_ball(name, vd)

    p = @player_dict[name]
    if p and @ball.attached_on?(p)
      @ball.attach = nil
      @ball.velocity = Vct.new_dr(vd, Config.ball_speed)
      @ball.step(10)
    end
  end

  def setup
    @width = Config.ground_width
    @height = Config.ground_height
    @observers = Set.new
    @score_a = 0
    @score_b = 0

    @players = []
    @player_dict  = {}
    @ball = BallInfo.new(Vct.new_random(@width, @height), Vct.new_dr( rand * PI * 2, 4))
    @player_aids = []

    @teama =[]
    @teamb = []

    Config.teama_names.zip(Config.teamb_names).each { |ta, tb|
      p = PlayerInfo.new(ta, Vct.new_random(@width, @height), Vct.new_dr(rand * PI * 2, Config.player_speed))      
      @players << p
      @player_dict[ta] = p
      @player_aids << AID.new(ta)
      @teama << p 

      p = PlayerInfo.new(tb, Vct.new_random(@width, @height), Vct.new_dr(rand * PI * 2, Config.player_speed))      
      @players << p
      @player_dict[tb] = p
      @player_aids << AID.new(tb)
      @teamb << p      
    }

    add_behaviour(MatchBehaviour.new)
    add_behaviour(ObserverRegisterBehaviour.new)    
    add_behaviour(PlayerChangeBehaviour.new)
  end
end



