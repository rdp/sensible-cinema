require 'win32/screenshot'

class ScreenTracker
  def initialize name_or_regex, x,y,x2,y2
    @hwnd = Win32::Screenshot::BitmapMaker.hwnd(name_or_regex) # save us 0.00445136 per time
    raise 'bad name--perhaps not running yet?' unless @hwnd
    @x = x; @y = y; @x2 = x2; @y2 = y2
    
    #max_x1, max_y1, max_x2, max_y2 = Win32::Screenshot::BitmapMaker.dimensions_for(hwnd)
    
  end
  
  def get_bmp
    Win32::Screenshot.hwnd_area(@hwnd, @x,@y,@x2,@y2, 0) {|h,w,bmp| return bmp}
  end
end

if $0 == __FILE__
  require 'rubygems'
  require 'sane'
  require_relative '../spec/spec.screen_tracker.rb'
end