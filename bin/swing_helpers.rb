require 'java'
module SensibleSwing 
 include_package 'javax.swing'
 [JButton, JFrame, JLabel, JPanel, JOptionPane,
   JFileChooser] # grab these constants (http://jira.codehaus.org/browse/JRUBY-5107)
 include_package 'java.awt'
 [FlowLayout, Font]
 include_class 'java.awt.event.ActionListener'
 JFile = java.io.File
 
 class ClickAction
  
  include ActionListener

  def initialize &block
    @block = block
    raise unless block_given?
  end
  
  def actionPerformed(event)
    # a click!
    @block.call
  end
 end

 class JButton
   def initialize *args
    super *args
    set_font Font.new("Tahoma", Font::PLAIN, 11)
   end
   def on_clicked &block
     # maybe it can only have one on click handler for now?
     handler = ClickAction.new &block
     add_action_listener handler
     self
   end
 end

 class JFrame
   def close
     dispose # sigh
   end
  end

end


# JOptionPane.showInputDialog(nil, "not implemented yet", "not implemented yet", JOptionPane::ERROR_MESSAGE)