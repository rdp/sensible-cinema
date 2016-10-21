=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end
require 'sane' # gem
require 'whichr' # gem
require 'mini_magick'

im_path = File.expand_path(File.dirname(__FILE__) + "/../vendor/") # convert.exe/identify.exe want to only be chosen first from here...
ENV['PATH'] = im_path.gsub('/', "\\") + ';' + ENV['PATH']

if RubyWhich.new.which('identify').length == 0 || RubyWhich.new.which('convert').length == 0
 puts 'appears you do not have imagemagick installed (or not in your path) -- please download and install it first! http://www.imagemagick.org/script/binary-releases.php for windows, for instance'
 raise
end

# helper for OCR'ing single digits that were screen captured
module OCR
  if OS.windows? 
    GOCR = File.expand_path(File.dirname(__FILE__) + "/../vendor/gocr049.exe") # known to work :)
  else
    if OS.mac?
      GOCR = "./vendor/gocr_mac"
      throw "Unable to run gocr? please report..." unless system(GOCR + " --help 2>/dev/null") # and hope :|
    else
      # linux
      require_relative 'check_installed_mac_linux'
      exit 1 unless CheckInstalledMacLinux.check_for_installed 'gocr'
      GOCR = "gocr"
    end
  end
  GOCR << " -C 0-9:/ " # these are the chars you are looking for...
  
  CACHE = {}
  
  # options are :might_be_colon, :should_invert
  def identify_digit memory_bitmap, options = {}
    # spawning a process is [on windows at least] actually pretty expensive--last time I looked at least
    if CACHE.has_key?(memory_bitmap)
      return CACHE[memory_bitmap] unless (defined?($OCR_NO_CACHE) && $OCR_NO_CACHE)
    else
      puts 'cache miss' if $DEBUG && $VERBOSE
    end
    
    if options[:might_be_colon]
      # do special processing and basically assert it has some darkness in there <sigh>
      total = (memory_bitmap.scan(/\x00{5}+/)).length
      if total >= 3 # really should be 4 for VLC
        # it had some darkness...therefore must be a colon!
        CACHE[memory_bitmap] = ":"
        return ":"
      end
    end
    image = MiniMagick::Image.read(memory_bitmap)
    # any operation on image is expensive, requires convert.exe in path...
    if options[:should_invert] 
      # hulu wants negate
      # but doesn't want sharpen, for whatever reason...
      # mogrify calls it negate...
      image.negate 
    end

    image.format(:pnm)
    # I think it's VLC full screen that wants sharpening...
    image.sharpen(2) if options[:sharpen] # hulu does *not* want sharpen, though I haven't checked it too closely...

    previous = nil
    p options if $DEBUG
    raise 'you must pass in OCR levels in the player description' unless options[:levels]
    for level in options[:levels]
      command = "#{GOCR} -l #{level} #{image.path} 2>#{OS.dev_null}"
      a = `#{command}`
      if a =~ /[0-9]/
        # it might be funky like "_1_\n"
        a.strip!
        a.gsub!('_', '')
        a = a.to_i
        return CACHE[memory_bitmap] = a
      end
    end
    # cache failures here, for VLC's hour clock' sake
    CACHE[memory_bitmap] = nil
    nil
  end
  
  def version
    `#{GOCR} -h 2>&1`
  end
  
  def clear_cache!
    CACHE.clear
    File.delete CACHE_FILE if File.exist?(CACHE_FILE)
  end
  
  CACHE_FILE = File.expand_path('~/.sensible-cinema-ocr.marshal')
  
  def serialize_cache_to_disk
    File.binwrite(CACHE_FILE, Marshal.dump(CACHE))
  end
  
  def unserialize_cache_from_disk  
    if File.exist? CACHE_FILE
      CACHE.merge!(Marshal.load(File.binread(CACHE_FILE)))
    end
  end
  
  def load_from_ocr_seed
    for file in Dir[__DIR__ + "/seed_ocr/*.bmp"]
      file =~ /(\d+)\.bmp/i
      digit = $1.to_i
      raise unless digit < 10
      CACHE[File.binread(file)] = digit
    end
  end
  
  extend self
  
end
