require 'rubygems'
require 'os'
success = true

ENV['PATH'] = '/opt/rdp_project_local/bin/:' + ENV['PATH'] # put local bin in first, has ffmpeg etc.

module CheckInstalledMac

 # should output an error message...
 def self.check_for_installed name
  # check for these with generic "does it run" command
  command = {"gocr" => "gocr --help", "convert" => "convert --help", "ffmpeg" => "ffmpeg -version", 'mplayer' => 'mplayer'}[name]
  raise 'unknown ' + name unless command # sanity check

  unless system("/opt/rdp_project_local/bin/#{command} 1>/dev/null 2>&1")
     name = 'ImageMagick' if name == 'convert' # special case this one...
     SimpleGuiCreator.show_message 'lacking dependency! Please install ' + name + ' by installing from the mac dependencies package from the website first'
     SimpleGuiCreator.open_url_to_view_it_non_blocking "http://sourceforge.net/projects/mplayer-edl/files/mac-dependencies/" # TODO test this out does it work?
     false
  else
    true
  end

 end
end
