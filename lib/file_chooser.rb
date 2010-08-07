require 'java'

module FileChooser

  # show a popup dialog prompting for them to select a file
  # pretty ugly
  def choose_file(title, use_this_dir = nil)
  
    fc = java.awt.FileDialog.new(nil, title)
    if use_this_dir
      # FileDialog only accepts it a certain way.
      dir = File.expand_path(use_this_dir).gsub(File::Separator, File::ALT_SEPARATOR)
      fc.setDirectory(dir) 
    end
    # lodo allow for a FileFilter, too...
    fc.show
    
    out = fc.get_file
    fc.remove_notify # allow out app to exit
    out
  end
  
  extend self
  
end

if __FILE__ == $0
  p FileChooser.choose_file("test1", '..')
end