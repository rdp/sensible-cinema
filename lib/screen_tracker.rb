require 'win32/screenshot'
require 'sane'
require 'yaml'
require_relative 'ocr'

class ScreenTracker
  
  def self.new_from_yaml yaml, callback
    settings = YAML.load yaml
    return new(settings["name"], settings["x"], settings["y"], settings["width"], 
        settings["height"], settings["use_class_name"], settings["digits"], callback)
  end
  
  attr_accessor :hwnd
  
  # digits are like {:hours => [100,5], :minute_tens, :minute_ones, :second_tens, :second_ones}
  # digits share the height start point, have their own x and width...
  def initialize name_or_regex,x,y,width,height,use_class_name=nil,digits=nil,callback=nil
    # cache to save us 0.00445136 per time LOL
    @name_or_regex = name_or_regex
    @use_class_name = use_class_name
    get_hwnd
    pps 'height', height, 'width', width if $VERBOSE
    raise 'poor dimentia' if width <= 0 || height <= 0
    max_x, max_y = Win32::Screenshot::Util.dimensions_for(@hwnd)
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
    if @y2 > max_y || @y2 == y
      raise 'poor height or wrong window' 
    end
    @digits = digits
    @displayed_warning = false
    pps 'using x',@x, 'from x', x, 'y', @y, 'from y', y,'x2',@x2,'y2',@y2,'digits', @digits if $VERBOSE
  end
  
  def get_hwnd
    if @name_or_regex.to_s.downcase == 'desktop'
      # full screen option
      assert !@use_class_name # not an option
      @hwnd = hwnd = Win32::Screenshot::BitmapMaker.desktop_window
      return
    else
      @hwnd = Win32::Screenshot::BitmapMaker.hwnd(@name_or_regex, @use_class_name)
    end

    # allow ourselves the 'found it message' selectively
    unless @hwnd
      until @hwnd
        print 'perhaps not running yet? [%s]' % @name_or_regex.inspect
        sleep 1
        STDOUT.flush
        @hwnd = Win32::Screenshot::BitmapMaker.hwnd(@name_or_regex, @use_class_name)
      end
      puts 're-found window'
    end

  end
  
  # gets the snapshot of "all the digits together"
  def get_bmp
    # Note: we no longer bring the window to the front tho...which it needs to be in both XP and Vista to work...sigh.
    Win32::Screenshot::BitmapMaker.capture_area(@hwnd,@x,@y,@x2,@y2) {|h,w,bmp| return bmp}
  end
  
  # gets snapshot of the full window
  def get_full_bmp
     Win32::Screenshot::BitmapMaker.capture_all(@hwnd) {|h,w,bmp| return bmp}
  end

  # writes out all screen tracking info to various files in the current pwd
  def dump_bmp filename = 'dump.bmp'
    File.binwrite filename, get_bmp
    File.binwrite 'all.' + filename, get_full_bmp
    dump_digits get_digits_as_bitmaps if @digits
  end
  
  def dump_digits digits
      @digit_count ||= 1
      for type, bitmap in get_digits_as_bitmaps
        File.binwrite type.to_s + '.' + @digit_count.to_s + '.bmp', bitmap
      end
      print 'debug dumped digits that Im about to parse:', @digit_count, "\n"
      @digit_count += 1
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
  
  # split out for unit testing purposes
  def identify_digit bitmap
    OCR.identify_digit(bitmap, @digits)
  end
  
  def wait_till_next_change
    original = get_bmp
    time_since_last = Time.now
    loop {
      current = get_bmp
      if current != original
        if @digits
          got = attempt_to_get_time_from_screen
          if @displayed_warning && got
            # reassure user :)
            p 'tracking it successfully again' 
            @displayed_warning = false
          end
          return got
        else
          puts 'screen time change only detected...'
          return
        end
      end
      sleep 0.02
      if(Time.now - time_since_last > 5)
        p 'warning--unable to track screen time for some reason' unless @displayed_warning
        time_since_last = Time.now
        @displayed_warning = true
        # reget window, just in case that's the problem...
        get_hwnd
      end
    }
  end
  
  def attempt_to_get_time_from_screen
    out = {}
    # force it to have two matching in a row, to avoid race conditions grabbing the digits...
    previous = nil # 0.08s [!] not too accurate...ltodo
    start = Time.now
    until previous == (temp = get_digits_as_bitmaps)
      previous = temp
      sleep 0.05 # allow youtube to update (sigh)
      # lodo it should probably poll *before* this, not here...maybe?
    end
    digits = previous
    
    dump_digits(digits) if $DEBUG            
    DIGIT_TYPES.each{|type|
      if digits[type]
        digit = identify_digit(digits[type])
        unless digit
          if $DEBUG || $VERBOSE
            @a ||= 1
            @a += 1
            @already_wrote ||= {}
            unless @already_wrote[digits[type]]
              p 'unable to identify capture!' + type.to_s + @a.to_s + ' capture no:' + @digit_count.to_s
              File.binwrite("bad_digit#{@a}#{type}.bmp", digits[type]) unless type == :hours
              @already_wrote[digits[type]] = true
            end
          end
          if type == :hours
            digit = 0 # this one can fail and that's ok in VLC bottom right
          else
            # early failure return
            return
          end
        else
          p " got digit #{type} as #{digit} which was captured as #{@digit_count} " if $DEBUG
        end
        out[type] = digit
      else
        # there isn't one specified as being on screen, so assume it is always zero (like youtube hour)...
        out[type] = 0
      end
    }
    out = "%d:%d%d:%d%d" % DIGIT_TYPES.map{ |type| out[type] }
    puts '', 'got new screen time ' + out + " tracking delta:" + (Time.now - start).to_s if $VERBOSE
    return out, Time.now-start
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