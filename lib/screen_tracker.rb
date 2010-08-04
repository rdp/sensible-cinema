require 'win32/screenshot'
require 'sane'
require 'yaml'
require_relative 'ocr'

class ScreenTracker
  
  def self.new_from_yaml yaml, callback
    settings = YAML.load yaml
    # heigth is shared...
    height = settings["height"]
    digits = settings["digits"]
    return new(settings["name"], settings["x"], settings["y"], settings["width"], settings["height"], digits, callback)
  end
  
  # digits like {:hours => [100,5], :minute_tens, :minute_ones, :second_tens, :second_ones}
  # digits share the height...
  def initialize name_or_regex,x,y,width,height,digits=nil,callback=nil
    # cache to save us 0.00445136 per time LOL
    if name_or_regex.to_s.downcase == 'desktop'
      # full screen option
      @hwnd = hwnd = Win32::Screenshot::BitmapMaker.desktop_window
    else
      @hwnd = Win32::Screenshot::BitmapMaker.hwnd(name_or_regex)
    end
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
    pps 'height', height, 'width', width if $VERBOSE
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
    @height = height
    @x = x; @y = y; @x2 = x+width; @y2 = y+height; @callback = callback    
    @max_x = max_x
    raise 'poor width or wrong window' if @x2 > max_x  || @x2 == x
    raise 'poor height or wrong window' if @y2 > max_y || @y2 == y
    @digits = digits
    pps 'using x',@x, 'from x', x, 'y', @y, 'from y', y,'x2',@x2,'y2',@y2 if $VERBOSE
  end
  
  def get_bmp
    # Note: we no longer bring the window to the front tho...which it needs to be in both XP and Vista to work...sigh.
    Win32::Screenshot::BitmapMaker.capture_area(@hwnd,@x,@y,@x2,@y2) {|h,w,bmp| return bmp}
  end
  
  def get_full_bmp
    Win32::Screenshot.hwnd(@hwnd, 0) {|h,w,bmp| return bmp}
  end
  
  def dump_bmp filename = 'dump.bmp'
    File.binwrite filename, get_bmp
    File.binwrite 'all.' + filename, get_full_bmp
    if @digits
      for type, bitmap in get_digits_as_bitmaps
        File.binwrite type.to_s + '.bmp', bitmap
      end
    end
  end
  
  DIGIT_TYPES = [:hours, :minute_tens, :minute_ones, :second_tens, :second_ones]
  # returns like {:hours => nil, :minutes_tens => raw_bmp, ...
  def get_digits_as_bitmaps
    # @digits are like {:hours => [100,5], :minute_tens => [x, width], :minute_ones, :second_tens, :second_ones}
    out = {}
    for type in DIGIT_TYPES
      assert @digits.key?(type)
      if @digits[type]
        x,w = @digits[type]
        if(x < 0)
          x = @max_x + x
        end
        out[type] = Win32::Screenshot::BitmapMaker.capture_area(@hwnd, x, @y, x+w, @y2) {|h,w,bmp| bmp}
      end
    end
    out
  end
  
  def get_relative_coords
    [@x,@y,@x2,@y2]
  end
  
  def wait_till_next_change
    original = get_bmp
    loop {
      current = get_bmp
      if current != original
        if @digits
          out = {}
          dump_bmp if $DEBUG            
          digits = get_digits_as_bitmaps # 0.08s [!] not too accurate...
          start = Time.now
          DIGIT_TYPES.each{|type|
            if digits[type]
              out[type] = OCR.identify_digit(digits[type])
            else
              out[type] = 0
            end
          }
          out = "%d:%d%d:%d%d" % DIGIT_TYPES.map{|type| out[type]}
          p 'got new screen time ' + out + " delta:" + (Time.now - start).to_s if $VERBOSE
          # if the window was in the background it will be all zeroes, so nil it out
          out = nil unless out =~ /[1-9]/
          return out, Time.now - start
        else
          puts 'screen time change only detected...' if $VERBOSE
        end
        return nil
      end
      sleep 0.02
    }
  end
  
  def process_forever_in_thread
    Thread.new {
      loop {
        out_time, delta = wait_till_next_change
        @callback.timestamp_changed out_time, delta
      }
    }
  end
  
end