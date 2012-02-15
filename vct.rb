
PI = 3.1415926535 


class Vct  
  def initialize(x, y, gendr = true)
    @x, @y = x, y
    if gendr
      gen_dr
    end
  end

  def Vct.fix_v(v)
    c = 2.0 * PI
    if v >= 0 and v < c
      return v
    end

    d = v - (v/c).to_i * c
    if d < 0
      d += c
    end
    d
  end


  def Vct.gen_xy(direction, abs)
    return abs * Math.cos(Vct.fix_v(direction)), abs * Math.sin(direction)
  end

  
  def Vct.new_dr(direct, abs) 
    direct = Vct.fix_v(direct)
    x, y = Vct.gen_xy(direct, abs)
    v = Vct.new(x, y, false)    
    v.direction = direct
    v.abs = abs
    v
  end

  def Vct.new_random(w, h)
    Vct.new(rand(w), rand(h))
  end
  

  def gen_dr
    begin
      @direction = Math.atan(@y/@x)
    rescue ZeroDivisionError
      @direction  = PI * 0.5
      if @y < 0
        @direction = - @direction
      end
    end
    if @x < 0
      @direction += PI
    end
    @direction = Vct.fix_v(@direction)
    @abs = Math.sqrt(@x * @x + @y * @y)
  end  

  def -@
    Vct.new(-@x, -@y)
  end

  def x
    @x
  end
  def y
    @y
  end

  def +(other)
    Vct.new(@x + other.x, @y + other.y)
  end
  
  def -(other)
    Vct.new(@x - other.x, @y - other.y)
  end
  
  def *(other)
    if other.instance_of?(Vct)
      (@x * other.x + @y * other.y).to_f
    else
      Vct.new_dr(@direction, @abs * other)
    end      
  end

  def cos_a(other)
    (@x * other.x + @y * other.y) / (@abs * other.abs)
  end

  def normalize(new_abs)
    Vct.new_dr(@direction, new_abs)
  end

  def mirror(md)
    Vct.new_dr(2 * md - @direction, @abs)
  end

  def move(dx, dy)
    Vct.new(@x + dx, @y + dy)
  end

  def abs
    @abs
  end
  def direction
    @direction
  end
  def rotate(dd)
    Vct.new_dr(@direction + dd, @abs)
  end

  #protected
  def abs=(abs)
    @abs = abs
  end  

  def direction=(direct)
    @direction = Vct.fix_v(direct)
  end
  def x=(x)
    @x = x
  end
  def y=(y)
    @y=y
  end
end
