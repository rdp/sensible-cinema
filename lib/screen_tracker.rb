require 'win32/screenshot'
require 'sane'
require 'yaml'

class ScreenTracker
  
  def self.new_from_yaml yaml
    settings = YAML.load yaml
    return new(settings["name"], settings["x"], settings["y"], settings["width"], settings["height"])
  end
  
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
end