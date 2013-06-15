require 'rubygems'
require 'os'
success = true

ENV['PATH'] = '/opt/rdp_project_local/bin/:' + ENV['PATH'] # put local bin in first, has ffmpeg etc.

module CheckInstalledMac

 # should output an error message...
 def self.check_for_installed name
  # check for these with generic "does it run"

  command = {"gocr" => "gocr --help", "convert" => "convert --help", "ffmpeg" => "ffmpeg -version", mplayer_local => mplayer_local}[name]

  raise 'unknown ' + name unless command # sanity check

  unless system("/opt/rdp_project_local/bin/#{command} 1>/dev/null 2>&1")
     name = 'ImageMagick' if name == 'convert' # special case...
     puts 'lacking dependency! Please install ' + name + ' by installing from the mac dependencies link from the website first'
     false
  else
    true
  end

 end
end