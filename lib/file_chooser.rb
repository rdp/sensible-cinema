module FileChooser

  def choose_file(title, use_this_dir = nil)
    fc = Java::javax::swing::JFileChooser.new("JRuby panel")
    fc.set_dialog_title(title)
    fc.setCurrentDirectory(java.io.File.new(use_this_dir)) if use_this_dir
    success = fc.show_open_dialog(nil)
    if success == Java::javax::swing::JFileChooser::APPROVE_OPTION
      fc.get_selected_file.get_absolute_path
    else
     nil
    end
  end
  extend self
  
end

if __FILE__ == $0
  p FileChooser.choose_file("test1", '..')

end