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
      @fr.set_location(0,0)
      @fr.set_size(2000, 2000) # ltodo better coords...
      # ltodo: disable people being able to get past it?
      # lodo set on top, for hulu' sake?
      
      @label = JLabel.new("  Blank section")
      @fr.add(@label)
      @label.repaint
      @label.revalidate
      
      @fr.set_resizable(false)
      @fr.set_visible(true)
      unblank_full_screen! # hide it
    end

    def self.blank_full_screen! seconds
      if seconds
        @label.set_text "   #{seconds} s" 
      else
        @label.set_text "  Blank section"
      end
      @fr.setAlwaysOnTop(true)
    end
    
    def self.unblank_full_screen!
      @fr.setAlwaysOnTop(false)
    end
    
    def self.shutdown
      @fr.dispose    
    end
    
  end
end