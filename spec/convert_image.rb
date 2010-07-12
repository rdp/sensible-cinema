require 'rubygems'
require 'sane'
require 'RMagick'

to = ARGV[1] || 'pnm'
    img = Magick::Image.from_blob(File.binread ARGV[0])
    png = img[0].to_blob {self.format = to } # TIFF
    File.open("picture10." + to, "wb") {|file| file.puts png}    