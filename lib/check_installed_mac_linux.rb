require 'rubygems'
require 'os'
success = true

ENV['PATH'] = '/opt/rdp_project_local/bin/:' + ENV['PATH'] # mac dep binary install dir package :| put local bin in first, has ffmpeg etc.

module CheckInstalledMacLinux

 # should output an error message...
 def self.check_for_installed name
  # check for these with generic "does it run" command
  command = {"gocr" => "gocr --help", "convert" => "convert --help", "ffmpeg" => "ffmpeg -version", 'mplayer' => 'mplayer'}[name]
  raise 'unknown ' + name unless command # sanity check

  if OS.x?
    if name == 'gocr'
      throw 'we dont check gocr mac here'
    end
    prefix = "/opt/rdp_project_local/bin/"
  else
    prefix = "" # just use system
  end
  unless system(last_command = "#{prefix}#{command} 1>/dev/null 2>&1")
     name = 'ImageMagick' if name == 'convert' # special case this one...
     if OS.x?
       SimpleGuiCreator.show_message 'lacking dependency! Please install ' + name + ' by installing from the mac dependencies package from the website first ' + last_command
       SimpleGuiCreator.open_url_to_view_it_non_blocking "http://sourceforge.net/projects/mplayer-edl/files/mac-dependencies/" # TODO test this out does it work?
     elsif OS.linux?
       SimpleGuiCreator.show_message 'lacking dependency! Please install ' + name + ' by installing using linux instructions like apt-get install XXX'
       SimpleGuiCreator.open_url_to_view_it_non_blocking "https://github.com/rdp/sensible-cinema/wiki/Linux-Dependencies"
     else
       throw 'huh os?'
     end
     false
  else
    true
  end

 end
end
