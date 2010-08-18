if RUBY_PLATFORM !~ /java/
  require_relative 'fake_blanker'
else
  
  require 'java'
  
  class Blanker 
    JFrame = javax.swing.JFrame
    JLabel = javax.swing.JLabel

    def self.startup
      @fr = JFrame.new("blanked section")
      @fr.default_close_operation = JFrame::EXIT_ON_CLOSE
      @fr.set_size(2000, 2000) # ltodo better size coords ?
      
      @label = JLabel.new("  Blank section")
      @fr.add(@label)
      @label.repaint
      @label.revalidate
      
      @fr.set_resizable(false)
      @fr.set_visible(true) # have to do this once, to ever see the thing
      @fr.setAlwaysOnTop(true)
      unblank_full_screen! # hide it
    end

    def self.blank_full_screen! seconds
      if seconds
        @label.set_text "   #{seconds} s" 
      else
        @label.set_text "  Blank section"
      end
      @fr.set_location(0,0)
    end
    
    def self.unblank_full_screen!
      # off screen...I hope.
      @fr.set_location(-2100, -2100)
    end
    
    def self.shutdown
      @fr.dispose    
    end
    
  end
end