require 'java'
module SensibleSwing 
 include_package 'javax.swing'
 [JButton, JFrame, JLabel, JPanel, JOptionPane,
   JFileChooser, JComboBox] # grab these constants (http://jira.codehaus.org/browse/JRUBY-5107)
 include_package 'java.awt'
 [FlowLayout, Font]
 include_class 'java.awt.event.ActionListener'
 JFile = java.io.File
 
 class JButton
   def initialize *args
    super *args
    set_font Font.new("Tahoma", Font::PLAIN, 11)
   end
  
   def on_clicked &block
     raise unless block
     add_action_listener do |e|
       block.call
     end
     self
   end
  
 end

 class JFrame
   def close
     dispose # sigh
   end
  end
  
  class JFileChooser
    # returns nil on failure...
    def execute
      success = show_open_dialog nil
      raise nil unless success == Java::javax::swing::JFileChooser::APPROVE_OPTION
      get_selected_file.get_absolute_path
    end
  end

end

# code examples
# JOptionPane.showInputDialog(nil, "not implemented yet", "not implemented yet", JOptionPane::ERROR_MESSAGE)