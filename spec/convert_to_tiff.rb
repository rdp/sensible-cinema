require 'rubygems'
require 'sane'
require 'RMagick'

    img = Magick::Image.from_blob(File.binread ARGV[0])
    png = img[0].to_blob {self.format = 'TIFF'}
    File.open("picture10.tif", "wb") {|file| file.puts png}
    