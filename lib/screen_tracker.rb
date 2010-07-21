require 'win32/screenshot'
require 'sane'
require 'yaml'

class ScreenTracker
  
  def self.new_from_yaml yaml, callback
    settings = YAML.load yaml
    return new(settings["name"], settings["x"], settings["y"], settings["width"], settings["height"], callback)
  end
  
  def initialize name_or_regex,x,y,width,height,callback=nil
    # cache to save us 0.00445136 per time LOL
    @hwnd = Win32::Screenshot::BitmapMaker.hwnd(name_or_regex)
    unless @hwnd
      print 'perhaps not running yet? [%s] START IT QUICKLY' % name_or_regex
      until @hwnd
        sleep 2
        print ' trying again .'
        STDOUT.flush
        @hwnd = Win32::Screenshot::BitmapMaker.hwnd(name_or_regex)
      end
      puts 'found window'
    end
    p 'height', height, 'width', width if $VERBOSE
    raise 'poor dimentia' if width <= 0 || height <= 0
    always_zero, always_zero, max_x, max_y = Win32::Screenshot::BitmapMaker.dimensions_for(@hwnd)
    if(x < 0 || y < 0)
      if x < 0
        x = max_x + x
      end
      if y < 0
        y = max_y + y
      end
    end
    @x = x; @y = y; @x2 = x+width; @y2 = y+height; @callback = callback    
    raise 'poor width or wrong window' if @x2 > max_x  || @x2 == x
    raise 'poor height or wrong window' if @y2 > max_y || @y2 == y    
    pps 'using x',@x, 'from x', x, 'y', @y, 'from y', y,'x2',@x2,'y2',@y2 if $VERBOSE
  end
  
  def get_bmp
    # Note: we no longer bring the window to the front tho...which it needs to be
    Win32::Screenshot::BitmapMaker.capture_area(@hwnd,@x,@y,@x2,@y2) {|h,w,bmp| return bmp}
  end
  
  def get_full_bmp
    Win32::Screenshot.hwnd(@hwnd, 0) {|h,w,bmp| return bmp}
  end
  
  def dump_bmp filename = 'dump.bmp'
    File.binwrite filename, get_bmp
    File.binwrite 'all.' + filename, get_full_bmp
  end
  
  def get_relative_coords
    [@x,@y,@x2,@y2]
  end
  
  def wait_till_next_change
    original = get_bmp
    loop {
      current = get_bmp
      if current != original
        return
      end
      sleep 0.05
    }
  end
  
  def process_forever_in_thread
    Thread.new {
      loop {
        wait_till_next_change
        print 'got a screen timestamp change' if $VERBOSE
        @callback.timestamp_changed
      }
    }
  end
  
end