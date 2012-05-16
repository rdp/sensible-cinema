require 'rubygems'
require 'os'
success = true

ENV['PATH'] = '/opt/rdp_project_local/bin/:' + ENV['PATH'] # put macports' bin in first

module CheckInstalledMac

 # should output an error message...
 def self.check_for_installed name
  # check for these with generic "does it run"

  command = {"gocr" => "gocr --help", "convert" => "convert --help", "ffmpeg" => "ffmpeg -version", "mplayer" => "mplayer"}[name]

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

if $0 == __FILE__
  for name in ['gocr', 'convert', 'mplayer', 'ffmpeg'] do
    if CheckInstalledMac.check_for_installed name
      puts 'has dep:' + name
    end
  end
end
