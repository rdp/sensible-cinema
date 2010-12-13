Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
    if RUBY_PLATFORM !~ /java/
  require_relative 'fake_blanker'
else
  
  require 'java'
  
  class Blanker 
    JFrame = javax.swing.JFrame
    JLabel = javax.swing.JLabel

    def self.startup
      @fr = JFrame.new("Sensible Cinema blanker-outer overlay window")
      @fr.default_close_operation = JFrame::EXIT_ON_CLOSE
      @fr.set_size(2000, 2000) # ltodo better size ?
      cp = @fr.getContentPane
      cp.setBackground(java.awt.Color.black);      
      
      @label = JLabel.new
      @label.set_text 'blanked'
      @fr.add(@label)
      @label.setForeground(java.awt.Color.white);
      @label.repaint
      @label.revalidate
      
      @fr.set_resizable(false)
      @fr.set_visible(true) # have to do this once, to ever see the thing
      # lodo does this really speed things up to pre-create it? that icon is a bit ugly...
      @fr.repaint
      unblank_full_screen! # and hide it to start
    end

    def self.blank_full_screen! seconds
      # somewhat hacky work around for doze: http://www.experts-exchange.com/Programming/Languages/Java/Q_22977145.html
      @fr.setAlwaysOnTop(false) 
      @fr.setAlwaysOnTop(true)
      @fr.set_location(0,0)
      @fr.repaint # early paint, just in case that helps it pop up faster :)
      if seconds
        @label.set_text "   #{seconds} s" 
      else
        @label.set_text "  Blank section"
      end
    end
    
    def self.unblank_full_screen!
      # move it off screen...
      @fr.set_location(-2100, -2100)
      @fr.repaint 0
    end
    
    def self.shutdown
      @fr.dispose
    end
    
  end
  
end