require 'java'
JFrame = javax.swing.JFrame
JPanel = javax.swing.JPanel


class Blanker
  
  def self.blank_full_screen!

    @fr = begin
      frame = JFrame.new("Random Points within a Circle")
      frame.default_close_operation = JFrame::EXIT_ON_CLOSE
      frame.set_size(400, 400)
      frame.show    
      
      fr = frame
      fr.set_resizable(false)
      
      fr.set_undecorated(true) unless fr.is_displayable
      
      # probably unnecessary
      panel = JPanel.new
      frame.add(panel)
      panel.repaint
      panel.revalidate
      gd = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice()
      gd.set_full_screen_window(fr)
      fr.set_visible(true)
      fr
    end
    @fr.set_visible(true)
  end
#       System.out.println("Probando Full Screen...");
#       JFrame fr = new JFrame();
#       fr.setTitle("Test Title");
#       fr.getContentPane().add(new JLabel("Test content"));
#       fr.setResizable(false);
#       if (!fr.isDisplayable()){
#           fr.setUndecorated(true);            
#       }
#       GraphicsDevice gd = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice();
#       gd.setFullScreenWindow(fr);
#       fr.setVisible(true);
#       Thread.sleep(5000);
#       System.exit(0);        
        
  def self.unblank_full_screen!
    require 'rubygems'
    require 'ruby-debug'
    #debugger
    @fr.set_visible(false)
    @fr.dispose
  end
  
end