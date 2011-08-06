=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end
require 'win32/screenshot'
require 'sane'
require 'yaml'
require File.dirname(__FILE__)+ '/ocr'
require 'ffi'

class ScreenTracker
  
  extend FFI::Library
  ffi_lib 'user32'
  # second parameter, pointer, LPRECT is FFI::MemoryPointer.new(:long, 4)
  # read it like rect.read_array_of_long(4)
  attach_function :GetWindowRect, [:long, :pointer], :int # returns a BOOL
  
  def self.new_from_yaml yaml, callback # callback can be nil, is used for timestamp changed stuff
    settings = YAML.load yaml
    return new(settings["name"], settings["x"], settings["y"], settings["width"], 
        settings["height"], settings["use_class_name"], settings["digits"], callback)
  end
  
  attr_accessor :hwnd
  
  # digits are like {:hours => [100,5], :minute_tens, :minute_ones, :second_tens, :second_ones}
  # digits share the height start point, have their own x and width...
  def initialize name_or_regex, x, y, width, height, use_class_name=nil, digits=nil, callback=nil
    # cache to save us 0.00445136 per time LOL
    @name_or_regex = name_or_regex
    @use_class_name = use_class_name
    pps 'height', height, 'width', width if $VERBOSE
    raise 'poor dimentia' if width <= 0 || height <= 0
    get_hwnd_loop_forever
    max_x, max_y = Win32::Screenshot::Util.dimensions_for(@hwnd)
    if(x < 0 || y < 0)
      if x < 0
        x = max_x + x
      end
      if y < 0
        y = max_y + y
      end
    end
    @x = x; @y = y; @x2 = x+width; @y2 = y+height; @callback = callback    
    @max_x = max_x
    raise "poor width or wrong window #{@x2} #{max_x} #{x}" if @x2 > max_x  || @x2 == x
    if @y2 > max_y || @y2 == y || @y2 <= 0
      raise "poor height or wrong window selected #{@y2} > #{max_y} || #{@y2} == #{y} || #{@y2} <= 0" 
    end
    if max_x == 0 || max_y == 0
      # I don't think we can ever get here, because of the checks above
      raise 'window invisible?'
    end
    @digits = digits
    @previously_displayed_warning = false
    @dump_digit_count = 1
    pps 'using x',@x, 'from x', x, 'y', @y, 'from y', y,'x2',@x2,'y2',@y2,'digits', @digits.inspect if $VERBOSE
  end
  
  def get_hwnd_loop_forever
    if @name_or_regex.to_s.downcase == 'desktop'
      # full screen option
      assert !@use_class_name # not an option
      @hwnd = hwnd = Win32::Screenshot::BitmapMaker.desktop_window
      return
    else
      @hwnd = Win32::Screenshot::BitmapMaker.hwnd(@name_or_regex, @use_class_name)
    end

    # display the 'found it message' only if it was previously lost...
    unless @hwnd
      until @hwnd
        print 'unable to find the player window currently [%s] (maybe need to start program or move mouse over it)' % @name_or_regex.inspect
        sleep 1
        STDOUT.flush

        hwnd = Win32::Screenshot::BitmapMaker.hwnd(@name_or_regex, @use_class_name)
        width, height = Win32::Screenshot::Util.dimensions_for(hwnd)
        p width, height
        @hwnd = hwnd
      end
      puts 're-established contact with window'
    end
    true
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
  def dump_bmps filename = 'dump.bmp'
    File.binwrite filename, get_bmp
    File.binwrite 'all.' + filename, get_full_bmp
    dump_digits(get_digits_as_bitmaps, 'dump_bmp') if @digits
  end
  
  def dump_digits digits, message
    p "#{message} dumping digits to dump no: #{@dump_digit_count} #{Time.now.to_f}"
    for type, bitmap in digits
      File.binwrite type.to_s + '.' + @dump_digit_count.to_s + '.bmp', bitmap    
    end
    File.binwrite @dump_digit_count.to_s + '.mrsh', Marshal.dump(digits)
    @dump_digit_count += 1
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
        x2 = x + w
        raise 'a digit width can never be negative #{w}' if w <= 0
        y2 = @y2
        width = x2 - x
        height = y2 - @y
        # lodo calculate these only once...
        out[type] = Win32::Screenshot::BitmapMaker.capture_area(@hwnd, x, @y, x2, y2) {|h,w,bmp| bmp}
      end
    end
    out
  end
  
  def get_relative_coords_of_timestamp_window
    [@x,@y,@x2,@y2]
  end
  
  def get_coords_of_window_on_display # yea
    out = FFI::MemoryPointer.new(:long, 4)
    ScreenTracker.GetWindowRect @hwnd, out
    out.read_array_of_long(4)
  end

  def identify_digit bitmap
    OCR.identify_digit(bitmap, @digits)
  end
  
  # we have to wait until the next change, because when we start, it might be half-way through
  # the current second...
  def wait_till_next_change
    original = get_bmp
    time_since_last_screen_change = Time.now
    loop {
      # save away the current time to try and be most accurate...
      time_before_scan = Time.now
      current = get_bmp
      if current != original
        if @digits
          got = attempt_to_get_time_from_screen time_before_scan
          if @previously_displayed_warning && got
            # reassure user :)
            p 'tracking it successfully again' 
            @previously_displayed_warning = false
          end
          return got
        else
          puts 'screen time change only detected... [unexpected]' # unit tests do this still
          return
        end
      else
        # no screen change detected ...
        sleep 0.02
        if(Time.now - time_since_last_screen_change > 2.0)
          # display a warning
          p 'warning--unable to track screen time for some reason [perhaps screen obscured or it\'s not playing yet, or paused?] ' + @hwnd.to_s
          p Win32::Screenshot::Util.dimensions_for(hwnd)
          @previously_displayed_warning = true
          time_since_last_screen_change = Time.now
          # also reget window hwnd, just in case that's the problem...(can be with VLC moving from title to title)
          get_hwnd_loop_forever
        end
      end
    }
  end
  
  def attempt_to_get_time_from_screen start_time
    out = {}
    # force it to have two matching snapshots in a row, to avoid race conditions grabbing the digits...
    # allow youtube to update (sigh) lodo just for utube
    previous = nil 
    sleep 0.05
    current = get_digits_as_bitmaps
    while previous != current
      previous = current
      sleep 0.05
      current = get_digits_as_bitmaps
      # lodo it should probably poll *before* calling this, not here...maybe?
    end
    assert previous == current
    digits = current = previous    
    DIGIT_TYPES.each{|type|
      if digits[type]
        digit = identify_digit(digits[type])
        unless digit
          bitmap = digits[type]
          # unable to identify a digit?
          if $DEBUG || $VERBOSE && (type != :hours)
            @a ||= 1
            @a += 1
            @already_wrote ||= {}
            unless @already_wrote[bitmap]
              p 'unable to identify capture!' + type.to_s + @a.to_s + ' dump:' + @dump_digit_count.to_s
              File.binwrite("bad_digit#{@a}#{type}.bmp", bitmap)
              @already_wrote[bitmap] = true
            end
          end
          if type == :hours
            digit = 0 # this one can fail and that's ok in VLC bottom right
          else
            # early (failure) return
            return nil
          end
        else
          p " got digit #{type} OCR as #{digit} which was captured to dump #{@dump_digit_count - 1} #{Time.now_f}" if $DEBUG
        end
        out[type] = digit
      else
        # there isn't one specified as being on screen, so assume it is always zero (like youtube hour)...
        out[type] = 0
      end
    }
    out = "%d:%d%d:%d%d" % DIGIT_TYPES.map{ |type| out[type] }
    puts '', 'got new screen time ' + out + " (+ tracking delta:" + (Time.now - start_time).to_s  + ")" if $VERBOSE
    return out, Time.now-start_time
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