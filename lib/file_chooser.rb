=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end
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
    Thread.new { sleep 2; fc.to_front } # it gets hidden, unfortunately, so try and bring it again to the front...
    fc.show
    if fc.get_file
      out = fc.get_directory + fc.get_file
    end
    fc.remove_notify # allow out app to exit
    out
  end
  
  extend self
  
end

if __FILE__ == $0
  p FileChooser.choose_file("test1", '..')
end