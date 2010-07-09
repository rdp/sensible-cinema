require 'win32/screenshot'

class ScreenTracker
  def initialize name_or_regex, x,y,width,height
    @hwnd = Win32::Screenshot::BitmapMaker.hwnd(name_or_regex) # save us 0.00445136 per time
    raise 'bad name--perhaps not running yet?' unless @hwnd
    raise 'poor dimentia' if width <= 0 || height <= 0
    if(x < 0 || y < 0)
      always_zero, always_zero, max_x, max_y = Win32::Screenshot::BitmapMaker.dimensions_for(@hwnd)
      if x < 0
        x = max_x + x
      end
      if y < 0
        y = max_y + y
      end
    end
    @x = x; @y = y; @x2 = x+width; @y2 = y+height
    
  end
  
  def get_bmp
    Win32::Screenshot.hwnd_area(@hwnd, @x,@y,@x2,@y2, 0) {|h,w,bmp| return bmp}
  end
  
  def get_relative_coords
    [@x,@y,@x2,@y2]
  end
  
end

if $0 == __FILE__
  require 'rubygems'
  require 'sane'
  require_relative '../spec/spec.screen_tracker.rb'
end