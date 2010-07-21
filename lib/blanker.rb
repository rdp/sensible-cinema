

class Blanker
  
  if RUBY_PLATFORM =~ /java/
    require 'java'
    JFrame = javax.swing.JFrame
    JPanel = javax.swing.JPanel
  
    def self.blank_full_screen!
      # a new screen each time as other jruby doesn't terminate as gracefully as we would like...
        frame = JFrame.new("Edited!") # ltodo take out...
        frame.default_close_operation = JFrame::EXIT_ON_CLOSE
        frame.set_location(0,0)
        frame.set_size(2000, 2000) # ltodo better coords...
        frame.show
        # lodo on top?
        
        fr = frame
        fr.set_resizable(false)
        
        fr.set_undecorated(true) unless fr.is_displayable
        
        # probably unnecessary
        panel = JPanel.new
        frame.add(panel)
        # frame.set_background()
        panel.repaint
        panel.revalidate
        # too heavy!
        # gd = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice()
        # gd.set_full_screen_window(fr)
        @fr = fr
        @fr.set_visible(true)
    end
  else
    require 'tk'
    Tk.root.iconify # start iconified
    def self.blank_full_screen!
      @fr ||= begin
        root = Tk.root
        #root.bind('1'){exit} # allow it to exit with left click
        root.attributes(:fullscreen=>true)
        root
      end
      @fr.attributes(:topmost => true)
    end
  
  end
  
  def self.unblank_full_screen!
    if @fr
      if RUBY_PLATFORM =~ /java/
        @fr.set_visible(false)
        @fr.dispose
      else
        @fr.attributes(:topmost => false)
      end
    end
  end
  
  @fr = nil # avoid warnings
  
end