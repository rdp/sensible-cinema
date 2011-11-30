require 'rubygems'
require 'os'
success = true

ENV['PATH'] = '/opt/local/bin' + ENV['PATH'] # macports' bin in first

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
    instrs = "please install mplayer-edl, see website http://rogerdpack.t28.net/sensible-cinema/content_editor.html"
    unless File.exist?('/opt/local/bin/mplayer')
      puts 'please install mplayer edl, ' + instrs
      return false
    end
    out = `mplayer -osd-verbose`
    if out =~ /unknown option on the command line/i
     puts 'maybe you have another macports mplayer already uninstalled? please $ port uninstall, then ' + instrs
     return false
    else
     return true
    end
  end

  # check for the others generically

  command = {"gocr" => "gocr --help", "convert" => "convert --help", "ffmpeg" => "ffmpeg -version"}[name]

  raise 'unknown ' + name unless command # sanity check

  unless system(command + " 1> " + OS.dev_null + " 2>" + OS.dev_null)
     name = 'ImageMagick' if name == 'convert' # special case...
     puts 'lacking dependency! Please install ' + name + ' by installing macports and running in terminal: $ sudo port install ' + name
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
