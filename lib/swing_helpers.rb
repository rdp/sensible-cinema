require 'java'
module SensibleSwing 
 include_package 'javax.swing'
 [JProgressBar, JButton, JFrame, JLabel, JPanel, JOptionPane,
   JFileChooser, JComboBox, JDialog, SwingUtilities] # grab these constants (http://jira.codehaus.org/browse/JRUBY-5107)
 include_package 'java.awt'
 [FlowLayout, Font]
 include_class java.awt.event.ActionListener
 JFile = java.io.File
 include_class java.awt.FileDialog
 
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
        java.lang.System.exit 1 # kills background proc...but we shouldn't let them do stuff while a background proc is running, anyway
      end
      get_selected_file.get_absolute_path
    end
    
    # match FileDialog
    def set_title x
      set_dialog_title x
    end
    
    def set_file f
      set_selected_file JFile.new(f)
    end
    alias setFile set_file
  end
  
  class FileDialog
    def go
      show
      File.expand_path(get_directory + '/' + get_file) if get_file
    end
  end
  
  class ModeLessDialog < JDialog
    def initialize title_and_display_text, close_button_text= 'Close'
      super nil
      lines = title_and_display_text.split("\n")
      set_title lines[0]
      get_content_pane.set_layout nil
      lines.each_with_index{|line, idx|
        jlabel = JLabel.new line
        jlabel.set_bounds(10, 15*idx, 400, 24)
        get_content_pane.add jlabel
      }
      close = JButton.new( close_button_text ).on_clicked {
        self.dispose
      }
      close.set_bounds(125,30+15*lines.length,70,25)
      get_content_pane.add close
      set_size 400, 100+15*lines.length
      set_visible true
      setDefaultCloseOperation JFrame::DISPOSE_ON_CLOSE
      setLocationRelativeTo nil # center it on the screen
    end
  end
end

require 'os'

class String
 def to_filename
   if OS.windows?
     self.gsub('/', "\\")
   else
    self
  end
 end
end

# code examples
# JOptionPane.showInputDialog(nil, "not implemented yet", "not implemented yet", JOptionPane::ERROR_MESSAGE)