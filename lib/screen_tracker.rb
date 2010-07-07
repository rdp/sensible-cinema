require 'win32/screenshot'

class ScreenTracker
  def initialize name_or_regex, x,y,x2,y2
    @hwnd = Win32::Screenshot::BitmapMaker.hwnd(name_or_regex) # save us 0.00445136 per time
    @x = x; @y = y; @x2 = x2; @y2 = y2
  end
  
  def get_bmp
    Win32::Screenshot.hwnd_area(@hwnd, @x,@y,@x2,@y2)
  end
end