Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
    require 'rubygems'
require 'sane'
require 'RMagick'

to = ARGV[1] || 'pnm'
    img = Magick::Image.read(File.binread ARGV[0])
    png = img[0].to_blob {self.format = to } # TIFF
    File.open("picture10." + to, "wb") {|file| file.puts png}    