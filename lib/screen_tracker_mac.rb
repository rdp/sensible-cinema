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

class ScreenTracker
  
  
  # digits are like {:hours => [100,5], :minute_tens, :minute_ones, :second_tens, :second_ones}
  # digits share the height start point, have their own x and width...
  def initialize name_or_regex, x, y, width, height, use_class_name=nil, digits=nil, callback=nil
    raise "must be desktop full screen in os x" unless name == 'desktop'
    @callback = callback
    @digits = digits
    @dump_digit_count = 1
    pps 'using desktop in mac', @digits
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
