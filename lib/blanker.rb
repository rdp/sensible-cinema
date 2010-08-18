if RUBY_PLATFORM !~ /java/
  require_relative 'fake_blanker'
else
  
  require 'java'
  
  class Blanker 
    JFrame = javax.swing.JFrame
    JPanel = javax.swing.JPanel
    
    def self.blank_full_screen!
      # a new screen each time as other jruby doesn't terminate as gracefully as we would like...
      @fr = JFrame.new("blanked section") # ltodo pass in param
      @fr.default_close_operation = JFrame::EXIT_ON_CLOSE
      @fr.set_location(0,0)
      @fr.set_size(2000, 2000) # ltodo better coords...
      # how to turn off title bar:
      # @fr.set_undecorated(true)
      # lodo on top?
      
      @fr.set_resizable(false)
      @fr.set_visible(true)
    end
    
    def self.unblank_full_screen!
      if @fr
        @fr.dispose
      end
    end
    
  end
end