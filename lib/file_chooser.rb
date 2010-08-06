module FileChooser

  def choose_file(title, use_this_dir)
    fc = Java::javax::swing::JFileChooser.new("JRuby panel")
    fc.set_dialog_title(title)
    #fc.setCurrentDirectory(
    success = fc.show_open_dialog(nil)
    if success == Java::javax::swing::JFileChooser::APPROVE_OPTION
      p 'success'
      return fc.get_selected_file.get_name
    else
     p 'cancel'
    end
  end
  extend self
  
end

if __FILE__ == $0
  p FileChooser.choose_file("test1")

end