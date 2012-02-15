require 'player'
require 'mas/mas'

include MAS

module Moderate
  class ModeratePlayerBehaviour < RespondPlayerBehaviour
    include ContractNetInitiator
    include ContractNetResponder
    def startup
      super    
      #install_cn_initiator("Football.term", "trans_ball", @gs.partner_names.collect {|tn| AID.new(tn)})
      install_cn_responder("trans_ball")

      @po = @agent.name[1..2].to_i    
      ps = proc { |msg|
        @inform = "transporting.ball"
      }
      @agent.receive_callback(ps, MessageSelector.match_ontology("transport.ball", false))
    end

    def defend_pos
      w = @gs.width
      case @po
      when 1
        return Vct.new(0.7598 * w, 0.15 * w)  #0.866 * 0.3 + 0.5 w, 0.3 * 0.5 . 30 degree
      when 2
        return Vct.new(0.5 * w , 0.3 * w)    # 0.5 * w , 0.3 * w,  90 degrees
      when 3
        return Vct.new(0.24 * w, 0.15 * w)  # 0.5 - 0.866 * 0.3 w , 0.3 * 0.5 w. 150 degree
      end
    end
    def obg_w
      w = @gs.width
      case @po
      when 1
        return [0.5 * w, w]
      when 2
        return [0.25 * w, 0.75 * w]
      when 3
        return [0, 0.5 * w]
      end
    end
    
    def attack_pos
      w = @gs.width
      h = @gs.height
      case @po
      when 1
        return Vct.new(0.8464 * w, h - 0.2 * w)  #0.866 * 0.4 + 0.5 w, 0.4 * 0.5 . 30 degree
      when 2
      return Vct.new(0.5 * w , h - 0.4 * w)    # 0.5 * w , 0.4 * w,  90 degrees
      when 3
        return Vct.new(0.1536 * w, h - 0.2 * w)  # 0.5 - 0.866 * 0. w , 0.4 * 0.5 w. 150 degree
      end
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
  
    def b_back
      @agent.change(defend_pos() - @gs.pos_me)
    end

    def random_v(v_me = nil)
      if not v_me
        v_me = @gs.player_velocity(@agent.name)
      end
      d = v_me.direction
      @agent.change(v_me.rotate(rand * 0.2 - 0.1))    
    end

    #
    # Some contract net responder related callbacks
    #
    def cn_propose_trans_ball(pos_p)
      a = 0.0
      d = (pos_p - @gs.pos_me).abs
      e = (@gs.pos_me - @gs.rival_gate_position).abs

      @gs.rival_names.each { |r|
        pos_rival = @gs.player_position(r) 
        m = (pos_p - pos_rival).abs
        n = (pos_rival - @gs.pos_me).abs
        s = (pos_rival - @gs.rival_gate_position).abs
      
        a += (n + m)/d + (s + n)/ e 
      }
      a
    end

    #
    # Some contract net initiator related callbacks
    # 
    def cn_cfp_trans_ball
      # evaluate the @gs.pos_me
      @gs.pos_me
    end
    
    def cn_cfpeval_trans_ball(*ps)
      #
      # Find who is the easiest of shuting at door, then send it the message to inform transporting of ball
      # The algorithm should be modified to add more issues later
      #
    
      la = ps.collect {|a, b | 
        [b, a]          
      }
      min_value, min_aid = la.max
      send_transport_msg(min_aid)
    end  
  
    def send_transport_msg(tn_aid)
      msg = ACLMessage.new(ACLMessage.REQUEST, {
                           "language" => "Football.term",
                           "ontology" => "transport.ball", 
                           "reply-with" => ACLMessage.new_id,
                         })
      msg['receivers'] << tn_aid
      msg['content'] = @gs.pos_me
      @agent.send_msg(msg)
      @infrom = "transported.ball"
      @agent.release_ball(@gs.player_position(tn_aid.name) - @gs.pos_me)
      @context.delete("transport")
    end

    def transport_ball
      if  @context['transport']
        return 
      end
      @context['transport'] = "Yes"
      initiate_cfp("Football.term", "trans_ball",  @gs.partner_names.collect {|tn| AID.new(tn)})
    
      #send_transport_msg(@gs.pos_me, min_tn)
    end

    def shutdoor( v_me)
      @inform = "shut.door" 
      @agent.release_ball(@gs.rival_gate_position - @gs.pos_me)
      if v_me.x < 0
        @agent.change(v_me.rotate(0.5 * PI))
      else
        @agent.change(v_me.rotate(1.5 * PI))
      end
    end

    def on_hold

      v_me = @gs.player_velocity(@agent.name)
      p_attack_me = attack_pos() - @gs.pos_me
      w = @gs.width
      
      gate_me = @gs.rival_gate_position - @gs.pos_me
      
      rival_dist_gate =  @gs.rival_names.collect {|ra|
        pos_ra = @gs.player_position(ra)      
        (@gs.rival_gate_position - pos_ra).abs
      } 
   
      rival_dist_me = @gs.rival_names.collect {|ra|
        pos_ra = @gs.player_position(ra)      
        (@gs.pos_me - pos_ra).abs
      }
      number_front_rival = 0
      rival_dist_me_cos_a = @gs.rival_names.collect {|ra|
        pos_ra = @gs.player_position(ra) - @gs.pos_me
        if gate_me.cos_a(pos_ra) > 0
          number_front_rival +=1 
          [pos_ra.abs, pos_ra]
        else
          nil
        end
      }
      
      closest_ra, pos_ra = rival_dist_me_cos_a.compact.min

      if not closest_ra
        closest_ra = @gs.width
      end

      rival_cos_a = @gs.rival_names.collect {|ra|
        pos_ra_me = @gs.player_position(ra) - @gs.pos_me       
        gate_me.cos_a(pos_ra_me)
      }    
      if gate_me.abs <= 0.3 * w and number_front_rival == 0
        shutdoor(v_me)
      elsif p_attack_me.y < 0.04 * w or number_front_rival <= 1
        @agent.change(gate_me)
      elsif closest_ra >= 0.07 * w
        @agent.change(p_attack_me)
      elsif closest_ra >= 0.05 * w
        assert(pos_ra)
        if pos_ra.x < 0
          @agent.change(pos_ra.rotate(0.5 * PI))
        else
          @agent.change(pos_ra.rotate(1.5 * PI))
        end
      else
        transport_ball
      end 
    end

    def on_assist
      p_attack_me = attack_pos() - @gs.pos_me
      
      if p_attack_me.abs > 30
        @agent.change(p_attack_me)
      else      
        random_v
      end    
    end

    def on_defend
      bh = @gs.ball_holder
      pos_holder = @gs.player_position(bh)
      
      v_holder = @gs.player_velocity(bh)
      
      p_hm = @gs.pos_me - pos_holder
      cos_ta = v_holder * p_hm
      
      assert(cos_ta.instance_of?(Float))
    
      p_hm_abs = p_hm.abs
      
      dp, up = obg_w 
    
      if @gs.pos_me.y >= @gs.height / 2
        back
      elsif pos_holder.y >= @gs.height / 2      
        random_v
      elsif cos_ta >= 0 and pos_holder.x >= dp and pos_holder.x <= up
        target = v_holder * (0.5 * p_hm_abs * p_hm_abs / cos_ta) - p_hm       
        @agent.change(target)
      else
        #@agent.change((pos_holder + @gs.self_gate_position) * 0.5 - @gs.pos_me)    
        @agent.change(-p_hm)      
      end    
    end 

    def on_idle 
      pos_ball = @gs.ball_position  
      #v_me = @gs.player_velocity(@agent.name)

      v_ball_me = pos_ball - @gs.pos_me
      if @inform == "transported.ball"
        random_v
      elsif @inform == 'transporting.ball'
        @agent.change(v_ball_me)
      else #if @inform == "shut.door" or @inform == nil
        gotoball = true
        @gs.partner_names.each { |pn|
          if v_ball_me.abs > (@gs.player_position(pn) - pos_ball).abs      
            gotoball = false
          end
        }
        if @gs.pos_me.y >= @gs.height * 0.5 && rand < 0.8
          b_back
        elsif gotoball
          @agent.change(v_ball_me)
        else
          random_v
        end  
      end      
    end  
  end

  def Moderate.behaviours
    [ModeratePlayerBehaviour.new]
  end
end

