#!/usr/bin/env ruby
require 'sdl'
require "config"

SDL.init( SDL::INIT_VIDEO )
screen = SDL::setVideoMode(Config.ground_width,Config.ground_height,16,SDL::SWSURFACE)
SDL::WM::setCaption('Ruby CUP Platform','ruby cup')


class Match
  attr_reader :score_a, :score_b
  def initialize(screen)
    @screen = screen
    @r_player = Config.player_radius
    @r_ball =  Config.ball_radius
    @score_a = 0
    @score_b = 0
    @color_ball = @screen.mapRGB(255, 255, 255)  
    @color_teama = @screen.mapRGB(240, 20, 20)  
    @color_teamb = @screen.mapRGB(20, 20, 240)
    @font = SDL::BMFont.open("font.bmp",SDL::BMFont::TRANSPARENT)
  end

  def parse_snap(tm, score_a, score_b, ball_info, *players_info)
    @tm = tm
    @score_a = score_a
    @score_b = score_b
    @ball_info = ball_info
    @players_info = players_info
  end

  def draw_ground
    gw = Config.ground_width
    gh = Config.ground_height

    #
    # Draw gates
    #
    @screen.drawFilledEllipse(0, gh * 0.4, 2, 2, @color_teama)
    @screen.drawFilledEllipse(0, gh * 0.6, 2, 2, @color_teama)

    @screen.drawFilledEllipse(gw - 2, gh * 0.4, 2, 2, @color_teamb)
    @screen.drawFilledEllipse(gw - 2, gh * 0.6, 2, 2, @color_teamb)
    
    #
    # Draw lines
    #
    @screen.drawLine(gw * 0.5 , 0, gw * 0.5 , gh, @color_ball)
    @screen.drawCircle(gw * 0.5 , gh * 0.5 , gw * 0.1, @color_ball)

    @screen.drawRect(0 , gh * 0.3, gw * 0.2 , gh * 0.4, @color_ball)
    @screen.drawRect(gw * 0.8 , gh * 0.3, gw * 0.2 , gh * 0.4, @color_ball)    
  end
  def draw   
    gw = Config.ground_width
    gh = Config.ground_height

    t = 0
    team_size = Config.team_size
    @players_info.each {   |title, x, y, vd|
      if t < team_size
        color_team = @color_teama
      else
        color_team = @color_teamb
      end

      t += 1
      @screen.drawFilledEllipse(x - @r_player, y - @r_player, @r_player + @r_player, @r_player + @r_player, color_team)  
      @font.textout(@screen, title, x - @r_player, y + @r_player)
    }
    holder, bx, by, vbv = @ball_info
    @screen.drawFilledEllipse(bx - @r_ball, by - @r_ball, @r_ball + @r_ball, @r_ball + @r_ball, @color_ball)
  end

  def draw_score
    @font.textout(@screen, "Score #{@score_a}: #{@score_b}", 10, 10)
  end  
end

require 'drb'

def run(screen)
  DRb.start_service()
  obj = DRbObject.new(nil, 'druby://localhost:8779')
  match = Match.new(screen)

  while true
    while event = SDL::Event2.poll
      case event
      when SDL::Event2::KeyDown, SDL::Event2::Quit
        exit
      end
    end

    #
    screen.fillRect(0,0,Config.ground_width,Config.ground_height,screen.mapRGB(64, 140, 46))
    match.draw_ground          
    begin
      n =  obj.snap     
      if n == nil
        raise DRb::DRbConnError.new("Nil returned")
      end
      match.parse_snap(*n)          
      match.draw
      match.draw_score
      screen.updateRect(0,0,0,0)

      sleep 0.06
    rescue DRb::DRbConnError=>e
      match.draw_score
      screen.updateRect(0,0,0,0)
      sleep 0.1
    end 
  end
end

if __FILE__ == $0
  run(screen)
end

