require 'rubygems'
require 'os'
success = true

# MPlayer OSX Extended instead of smplayer... ?
module CheckInstalledMac
 def self.check_for_installed name
  if name == 'mencoder'
    output = `mencoder --fail 2>&1`
    if output =~ /mencoder/i
      # success, it is installed
      return true
    else
      # fall through
    end
  end

  command = {"gocr" => "gocr --help", "convert" => "convert --help", 
    "mplayer" => "mplayer", "mencoder" => "fakey", "ffmpeg" => "ffmpeg -version"}[name]

  raise 'unknown ' + name unless command # double check

  unless system(command + " 1> " + OS.dev_null + " 2>" + OS.dev_null)
     name = 'ImageMagick' if name == 'convert' # special case...
     puts 'lacking dependency! Please install ' + name + ' by running $ sudo port install ' + name
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
