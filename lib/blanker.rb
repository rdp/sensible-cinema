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
      @fr.set_visible(false) # display it later
    end

    def self.blank_full_screen! seconds
      if seconds
        @label.set_text "   #{seconds} s" 
      else
        @label.set_text "  Blank section"
      end
      @fr.set_visible(true)
    end
    
    def self.unblank_full_screen!
      @fr.set_visible(false)
    end
    
    def self.shutdown
      @fr.dispose    
    end
    
  end
end