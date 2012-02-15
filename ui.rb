# SDL random ellipses
# Author: Wayne Conrad <wconrad@yagni.com>

require 'sdl'

def show(function)

  event = SDL::Event.new
  screen = SDL::setVideoMode(640, 480, 16, SDL::SWSURFACE|SDL::ANYFORMAT)

  image = SDL::Surface.loadBMP("icon.bmp")
  image.setColorKey(SDL::SRCCOLORKEY, 0)
  image = image.displayFormat

  loop do
    color = screen.mapRGB(rand(256),rand(256),rand(256))
    x = rand(screen.w)
    y = rand(screen.h)
    xr = rand(80)
    yr = rand(80)

    a =  screen.public_methods.sort

    eval("screen.#{function}(x, y, xr, yr, color)")

    if event.poll != 0 then
      case event.type
      when SDL::Event::QUIT
        exit
      when SDL::Event::MOUSEBUTTONDOWN
        break
      when SDL::Event::KEYDOWN
        exit if event.keySym == SDL::Key::ESCAPE
        break
      end
    end
    SDL::Key.scan
    sleep 1
    screen.updateRect(0, 0, 0, 0)
  end
end

srand
SDL.init SDL::INIT_VIDEO
show("drawEllipse")

