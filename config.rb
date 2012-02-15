
class Config
  def Config.ground_width
    740
  end
  def Config.ground_height
    480
  end
  
  def Config.player_radius
    6
  end
  
  def Config.ball_radius
    2
  end
  
  def Config.player_speed
    7
  end
  
  def Config.ball_speed
    5
  end

  def Config.player_names
    ["A1", "A2", "A3", "B1", "B2", "B3"]
  end

  def Config.teama_names
    ["A1", "A2", "A3"]
  end

  def Config.teamb_names
    ["B1", "B2", "B3"]
  end

  def Config.team_size
    3
  end  
end

def assert(expr)
  if not expr
    if block_given?
      yield    
    end
    
    raise "assert failed" 
  end
end
