require 'rubygems'
require 'os'
success = true

ENV['PATH'] = '/opt/local/rdp_projects/bin/mplayer:' + ENV['PATH'] # macports' bin in first

module CheckInstalledMac

 # should output an error message...
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

  if name == 'mplayer'
    unless File.exist?('/opt/local/rdp_projects/bin/mplayer')
      puts "please install mplayer edl, please install mplayer-edl, see website http://rogerdpack.t28.net/sensible-cinema/content_editor.html"
      return false
    end
    return true
  end

  # check for the others generically

  command = {"gocr" => "gocr --help", "convert" => "convert --help", "ffmpeg" => "ffmpeg -version"}[name]

  raise 'unknown ' + name unless command # sanity check

  unless system(command + " 1> " + OS.dev_null + " 2>" + OS.dev_null)
     name = 'ImageMagick' if name == 'convert' # special case...
     puts 'lacking dependency! Please install ' + name + ' by installing the contrib pkg from the website'
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
