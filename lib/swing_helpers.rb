require 'java'
module SensibleSwing 
 include_package 'javax.swing'
 [JButton, JFrame, JLabel, JPanel, JOptionPane,
   JFileChooser, JComboBox, JDialog, SwingUtilities] # grab these constants (http://jira.codehaus.org/browse/JRUBY-5107)
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
    # raises on failure...
    def go
      success = show_open_dialog nil
      unless success == Java::javax::swing::JFileChooser::APPROVE_OPTION
        raise 'did not choose one' # don't kill background proc...
      end
      get_selected_file.get_absolute_path
    end
  end
  #showMessageDialog JOptionPane
  class ModeLessDialog < JDialog
    def initialize title_and_display_text, close_button_text= 'Close'
      super nil
      set_title title_and_display_text.split("\n")[0]
      get_content_pane.set_layout nil
      title_and_display_text.split("\n").each_with_index{|line, idx|
        jlabel = JLabel.new line
        jlabel.set_bounds(10, 15*idx, 400, 24)
        get_content_pane.add jlabel
      }
      close = JButton.new( close_button_text ).on_clicked {
        self.dispose
      }
      close.set_bounds(125,50,70,25)
      get_content_pane.add close
      set_size 400,125   
      set_visible true
      setDefaultCloseOperation JFrame::DISPOSE_ON_CLOSE
      setLocationRelativeTo nil # center it on the screen
    end
  end
end

# code examples
# JOptionPane.showInputDialog(nil, "not implemented yet", "not implemented yet", JOptionPane::ERROR_MESSAGE)