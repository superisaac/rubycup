#
# player.rb
# PlayerAgent
# 1: Load self defined wisdoms
# 2: Rece match snapshot from match agent
# 3: Send user control commands
#
# Written 
#

require "mas/mas"
require "vct"
require 'config'
include MAS



class TeamAMatchStatus
  attr_reader :ok, :partner_names, :team_names, :rival_names, :pos_me, :width, :height
  def initialize(name)
    @agent_name = name
    @ok = false
    @sign = name[0, 1]  # only A or B are legal
    assert(@sign == "A" || @sign == "B")
   
    @team_names = Set.new Config.player_names.grep(/#{@sign}/)     
    @rival_names = Set.new Config.player_names.reject {|x| x=~/#{@sign}/ }
    assert(@team_names.size == Config.player_names.size() / 2)

    @partner_names = Set.new(@team_names.clone.reject {|x| x =~ /#{@agent_name}/})

    @width = Config.ground_height
    @height = Config.ground_width
    
  end
  #
  # width of playground from global view
  #
  def g_width 
    Config.ground_width
  end
  #
  # height of playground from global view
  #
  def g_height 
    Config.ground_height
  end  
  #
  # gate position of selves
  #
  def self_gate_position
    Vct.new(@width /2, 0)
  end
  #
  # rival's gate position
  #
  def rival_gate_position
    Vct.new(@width /2, height)
  end
  # funciton p2t
  # public coordination to team view( the view of team A)
  #
  def p2t(x, y)
    Vct.new(g_height - y, x)
  end

  # funciton p2tv
  # public coordination to team view( the view of team A)
  # with direction and abs infomation
  def p2tv(vd, a)
    assert(vd <= 2 * PI && vd >= 0)
    d = vd + 0.5 * PI
    if d > 2 * PI
      d -= 2 * PI
    end
    Vct.new_dr(d, a)
  end

  # funciton t2p
  # team coordination  to public view( the view of team A)
  #
  def t2p(x, y)
    Vct.new(y, g_height - x)
  end

  # funciton t2pv
  # team coordination to public view( the view of team A)
  # in direction 
  def t2pv(v)
    v.direction - 0.5 * PI
  end
 
  #
  # parse match snapshot from match agent
  # change position's from public view to team view
  #
  def parse_snap(tm, score_a, score_b, ball_info, *players_info)
    @tm = tm
    @score_a = score_a
    @score_b = score_b
    @ball_info = [ball_info[0], p2t(ball_info[1], ball_info[2]), p2tv(ball_info[3], Config.ball_speed)]
    @players_info = Hash.new
    players_info.each { |pinfo|
      @players_info[pinfo[0]] =  [p2t(pinfo[1], pinfo[2]), p2tv(pinfo[3], Config.player_speed)]
    }
    @ok = true
    @pos_me = @players_info[@agent_name][0]
  end
  #
  # get the ball holder's name
  #
  def ball_holder
    if @ball_info[0] == 'none'
      return nil
    else
      return @ball_info[0]
    end
  end 
  #
  # get the ball's position
  #
  def ball_position
    @ball_info[1]
  end
  #
  # get the player's position by name
  #
  def player_position(name)
    @players_info[name][0]
  end
  #
  # get the player's velocity by name
  #
  def player_velocity(name)
    @players_info[name][1]
  end

end


#
# TeamBMatchStatus is the subclass of TeamAMatchStatus
# only some coordinate changing methods are overloaded
#
class TeamBMatchStatus < TeamAMatchStatus
  def p2t(x, y)
    Vct.new(y, g_width - x)
  end 
  
  def p2tv(vd, r)
    assert(vd <= 2 * PI  && vd >= 0) {
      puts "vd is #{vd}"
    }
    d = vd + 1.5 * PI
  
    Vct.new_dr(d, r)
  end

  def t2p(x, y)
    Vct.new(g_width - y, x)
  end

  def t2pv(v)
    v.direction - 1.5 * PI
  end
end


class PlayerBehaviour < CyclicBehaviour
  def initialize
    super(0.1)
  end
  def skip
    not(@agent.gs.ok) or super
  end
end
 

class RespondPlayerBehaviour < PlayerBehaviour
  def on_idle
  end
  def on_hold   
  end 
  def on_assist
  end
  def on_defend
  end

  def startup
    super
    @gs = @agent.gs
    @infom = nil
    @context = nil
    @last_action = nil
  end
  def touch_context(word)
    if @last_action != word
      @context = Hash.new
      @last_action = word
    end
  end
  def action
    bh = @gs.ball_holder
    if bh == nil   # no player holding the ball
      touch_context("idle")
      on_idle
    elsif bh == @agent.name # Holder of ball  
      touch_context("hold")
      @inform = nil
      on_hold
    elsif bh[0] == @agent.name[0]  # Team member
      touch_context("assist")
      @inform = nil
      on_assist
    else                           # ball hold by rival, Defend 
      touch_context("defend")
      @inform = nil
      on_defend
    end      
  end
end

class PlayerAgent < Agent
  attr_reader :gs 

  def setup    
    #add_behaviour(RecvSnapBehaviour.new)

    if @aid.name =~ /A/      
      @gs = TeamAMatchStatus.new name
    else
      @gs = TeamBMatchStatus.new name     
    end

    if arguments.size >= 1
      mwis = arguments[0]
    else
      mwis = "stupid"
    end

    require "wisdoms/#{mwis}/#{mwis}.rb"
    bhs_teama = "#{mwis.capitalize}.behaviours"

    @behavs = eval("#{bhs_teama}")
    @behavs.each { |b|
      add_behaviour(b)
    }
    @behavs = nil    

    ps = proc { |msg|
      @gs.parse_snap(*msg['content'])
    }
    receive_callback(ps, MessageSelector.match_performative(ACLMessage.INFORM, false))

  end

  def change(v)
    msg = ACLMessage.new(ACLMessage.REQUEST, {
                           "language" => "football.term",
                           "ontology" => "change.velocity", 
                           "reply-with" => "hihi#{name}",
                         })
   
    v1 = @gs.t2pv(v)

    msg['content'] =  v1
    msg['receivers'] << AID.new("Match")

    send_msg(msg)
  end

  
  def release_ball(v)
    msg = ACLMessage.new(ACLMessage.REQUEST, {
                           "language" => "football.term",
                           "ontology" => "release.ball", 
                           "reply-with" => "release.ball.#{name}",
                         })
    v = @gs.t2pv(v)
    msg['content'] = v
    msg['receivers'] << AID.new("Match")
    send_msg(msg)
  end
end


