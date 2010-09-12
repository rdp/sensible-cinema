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
      
      @label = JLabel.new
      @fr.add(@label)
      @label.repaint
      @label.revalidate
      
      @fr.set_resizable(false)
      @fr.set_visible(true) # have to do this once, to ever see the thing
      # lodo does this really speed things up to pre-create it? that icon is a bit ugly...
      unblank_full_screen! # and hide it to start
    end

    def self.blank_full_screen! seconds
      if seconds
        @label.set_text "   #{seconds} s" 
      else
        @label.set_text "  Blank section"
      end
      # somewhat hacky work around for doze: http://www.experts-exchange.com/Programming/Languages/Java/Q_22977145.html
      @fr.setAlwaysOnTop(false) 
      @fr.setAlwaysOnTop(true)
      @fr.set_location(0,0)
    end
    
    def self.unblank_full_screen!
      # off screen...
      @fr.set_location(-2100, -2100)
    end
    
    def self.shutdown
      @fr.dispose
    end
    
  end
  
end