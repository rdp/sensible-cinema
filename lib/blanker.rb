require 'java'
JFrame = javax.swing.JFrame
JPanel = javax.swing.JPanel


class Blanker
  
  def self.blank_full_screen!

    @frame = frame = JFrame.new("Random Points within a Circle")
    frame.default_close_operation = JFrame::EXIT_ON_CLOSE
    frame.set_size(400, 400)
    frame.show    
    
    # probably unnecessary
    panel = JPanel.new
    frame.add(panel)
    panel.repaint
    panel.revalidate
  end
  
  def self.unblank_full_screen!
    @frame.close
  end
  
end