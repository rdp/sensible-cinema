require 'rubygems'
require 'sane'
require 'RMagick'

    img = Magick::Image.from_blob(File.binread ARGV[0])
    png = img[0].to_blob {self.format = 'PNM' } # TIFF
    File.open("picture10.pnm", "wb") {|file| file.puts png}
    