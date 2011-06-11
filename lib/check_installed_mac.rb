require 'rubygems'
require 'os'
success = true

# MPlayer OSX Extended instead of mplayer... ?

for string, name in {"gocr -v" => "gocr", "convert -v" => "imagemagick", "mplayer -v" => "mplayer", "ffmpeg -v" => "ffmpeg"}
  puts 'lacking dependency! Please install ' + name unless system(string + "2>" + OS.dev_null)   
end
