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
require 'sane'
require 'yaml'
require File.dirname(__FILE__)+ '/ocr'
require 'ffi'
require 'win32/screenshot'

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
      raise 'window invisible???'
    end
    @digits = digits
    @previously_displayed_warning = false
    @dump_digit_count = 1
    pps 'using x',@x, 'from x', x, 'y', @y, 'from y', y,'x2',@x2,'y2',@y2,'digits', @digits.inspect if $VERBOSE
  end
  
  def get_hwnd_loop_forever
    if @name_or_regex.to_s.downcase == 'desktop'
      # full screen 'use the desktop' option
      assert !@use_class_name # window "class name" and desktop is not an option
      @hwnd = Win32::Screenshot::BitmapMaker.desktop_window
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

  DIGIT_TYPES = [:hours, :minute_tens, :minute_ones, :second_tens, :second_ones]
  
  def capture_area hwnd, x, y, x2, y2
    out[type] = Win32::Screenshot::BitmapMaker.capture_area(hwnd, x, y, x2, y2) {|h,w,bmp| bmp}
  end
  
  def get_relative_coords_of_timestamp_window
    [@x,@y,@x2,@y2]
  end
  
  def get_coords_of_window_on_display # yea
    out = FFI::MemoryPointer.new(:long, 4)
    ScreenTracker.GetWindowRect @hwnd, out
    out.read_array_of_long(4)
  end

end
