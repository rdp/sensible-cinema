require 'rubygems'
require 'os'
success = true

# MPlayer OSX Extended instead of smplayer... ?

for string, name in {"gocr --help" => "gocr", "convert --help" => "imagemagick", "mplayer -version" => "mplayer", "ffmpeg -version" => "ffmpeg"}
  puts 'lacking dependency! Please install ' + name unless system(string + "2>" + OS.dev_null)   
end
