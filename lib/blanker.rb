if RUBY_PLATFORM !~ /java/
  require_relative 'fake_blanker'
else

require 'java'

class Blanker 
  JFrame = javax.swing.JFrame
  JPanel = javax.swing.JPanel
  
  def self.blank_full_screen!
    # a new screen each time as other jruby doesn't terminate as gracefully as we would like...
    frame = JFrame.new("blanked section") # ltodo pass in param
    frame.default_close_operation = JFrame::EXIT_ON_CLOSE
    frame.set_location(0,0)
    frame.set_size(2000, 2000) # ltodo better coords...
    frame.show
    # lodo on top?
    
    fr = frame
    fr.set_resizable(false)
    
    fr.set_undecorated(true) unless fr.is_displayable
    
    # probably unnecessary
    #panel = JPanel.new
    #frame.add(panel)
    # frame.set_background() # set background color
    #panel.repaint
    #panel.revalidate
    @fr = fr
    @fr.set_visible(true)
  end
  
  def self.unblank_full_screen!
      if @fr
        @fr.dispose
      end
  end
  
end
end