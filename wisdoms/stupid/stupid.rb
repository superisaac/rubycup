require 'player'
module Stupid
  class StupidPlayerBehaviour < RespondPlayerBehaviour
    def startup
      super
      @state = 0
    end
    def back(v_me = nil)
      if not v_me
        v_me = @gs.player_velocity(@agent.name)
        
      end
      d = v_me.direction
      if d < 1.3 * PI and d >= 0.5 * PI
        @agent.change(v_me.rotate(0.05 * PI))
      elsif (d < 0.5 * PI and d > 0 ) or (d > 1.7 * PI)
        @agent.change(v_me.rotate(-0.05 * PI))
      end
    end
    
    def random_v(v_me = nil)
      if not v_me
        v_me = @gs.player_velocity(@agent.name)
      end
      d = v_me.direction
      @agent.change(v_me.rotate(rand * 0.2 - 0.1))    
    end


    def on_hold
      v_me = @gs.player_velocity(@agent.name)
      pos_me = @gs.player_position(@agent.name) 
      
      if (@gs.rival_gate_position - pos_me).abs <= 150
        @inform = "shut.door"
        @agent.release_ball((@gs.rival_gate_position - pos_me).normalize(4))
        @agent.change(-v_me)
        @state = 1
      else
        @agent.change((@gs.rival_gate_position - pos_me).normalize(5))
      end
    end
    
    def on_assist
      bh = @gs.ball_holder
      pos_holder = @gs.player_position(bh)
      pos_me = @gs.player_position(@agent.name)
      v_holder = @gs.player_velocity(bh)
      #v_me = @gs.player_velocity(@agent.name)
      v_holder_me = (pos_holder - pos_me + v_holder)

      if pos_me.y >= @gs.height / 2
        back
      else      
        random_v
      end    
    end
    def on_defend
      
      bh = @gs.ball_holder
      pos_holder = @gs.player_position(bh)
      pos_me = @gs.player_position(@agent.name)
      v_holder = @gs.player_velocity(bh)
      #v_me = @gs.player_velocity(@agent.name)
      v_holder_me = (pos_holder - pos_me + v_holder)    

      if pos_me.y >= @gs.height / 2
        back
      elsif pos_holder.y >= @gs.height / 2      
        random_v
      else      
        @agent.change(v_holder_me)
      end    
    end

    def on_released
      pos_me = @gs.player_position(@agent.name) 
      if pos_me.y >= @gs.height / 2
        @agent.change(Vct.new_dr(1.5 * PI, 5))
      else
        super
      end
    end

    def on_idle 
      pos_me = @gs.player_position(@agent.name)    
      pos_ball = @gs.ball_position  
      #v_me = @gs.player_velocity(@agent.name)
      
      v_ball_me = pos_ball - pos_me
      gotoball = true
      @gs.partner_names.each { |pn|
        if v_ball_me.abs > (@gs.player_position(pn) - pos_ball).abs      
          gotoball = false
        end
      }
    
      if pos_me.y >= @gs.height / 2
        back
      elsif gotoball
        @agent.change(v_ball_me)
      else
        random_v
      end      
    end  
  end



  def Stupid.behaviours
    [StupidPlayerBehaviour.new]
  end
end
