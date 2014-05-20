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

require 'java'

class ScreenTracker
  
  # digits are like {:hours => [100,5], :minute_tens, :minute_ones, :second_tens, :second_ones}
  # digits share the height start point, have their own x and width...
  def initialize name_or_regex, x, y, width, height, use_class_name=nil, digits=nil, callback=nil
    raise "must be desktop full screen in os x" unless name_or_regex == 'desktop'
    @x = x; @y = y; @x2 = x+width; @y2 = y+height; @callback = callback
    @digits = digits
    @dump_digit_count = 1
    pps 'using desktop in mac', @digits
    @robot = java.awt.Robot.new
  end
  
  # gets the snapshot of "all the digits together"
  def get_bmp
    get_bmp_by_coords @x,@y,@x2,@y2
  end
  
  def get_bmp_by_coords x,y,x2,y2
    img = @robot.createScreenCapture(java.awt.Rectangle.new(java.awt.Toolkit.getDefaultToolkit().getScreenSize()))
    baos = java.io.ByteArrayOutputStream.new
    #javax.imageio.ImageIO.write(img, "BMP", java.io.File.new("filename.bmp"))
    javax.imageio.ImageIO.write(img, "BMP", baos)
    as_string = String.from_java_bytes(baos.to_byte_array)
  end
  
  # gets snapshot of the full window
  def get_full_bmp
     dim = java.awt.Toolkit.getDefaultToolkit().getScreenSize()
     get_bmp_by_coords 0,0, dim.width, dim.height
  end

  def capture_area hwnd, x, y, x2, y2
    get_bmp_by_coords x, y, x2, y2 # ignore hwnd
  end
  
end
