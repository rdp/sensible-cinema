require 'java'
module SensibleSwing 
 include_package 'javax.swing'
 [JButton, JFrame, JLabel, JPanel, JOptionPane,
   JFileChooser, JComboBox, JDialog] # grab these constants (http://jira.codehaus.org/browse/JRUBY-5107)
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
    def go
      success = show_open_dialog nil
      unless success == Java::javax::swing::JFileChooser::APPROVE_OPTION
        puts "did not choose one" 
        java.lang.System.exit 1
      end
      get_selected_file.get_absolute_path
    end
  end
  #showMessageDialog JOptionPane
  class ModeLessDialog < JDialog
    attr_accessor :close_button
    def initialize title_and_display_text
      super
      set_title title_and_display_text
      jlabel = JLabel.new title_and_display_text
      jlabel.set_bounds(10, 10,136,14)
      add jlabel
    
      close = JButton.new( "Close" ).on_clicked {
        self.dispose
      }
      close.set_bounds(50,50,50,75)
      add close
      set_size 150,100
      @close_button = close

      #textdialog.getContentPane().add(child);
    end
  end
  
  
end

# code examples
# JOptionPane.showInputDialog(nil, "not implemented yet", "not implemented yet", JOptionPane::ERROR_MESSAGE)