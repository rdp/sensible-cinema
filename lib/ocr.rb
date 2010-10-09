im_path = File.expand_path(File.dirname(__FILE__) + "/../vendor/imagemagick") # convert.exe wants to only be chosen from here...
ENV['PATH'] = im_path + ';' + ENV['PATH']

# helper for OCR'ing single digits that were screen captured
module OCR
  
  GOCR = File.expand_path(File.dirname(__FILE__) + "/../vendor/gocr048.exe -C 0-9:/ ")
  
  CACHE = {}
  
  # options are :might_be_colon, :should_invert
  def identify_digit memory_bitmap, options = {}
    require 'mini_magick' # here because of installation woe, but actually not a big slowdown

    if CACHE.has_key?(memory_bitmap)
      return CACHE[memory_bitmap] unless (defined?($OCR_NO_CACHE) && $OCR_NO_CACHE)
    else
      puts 'cache miss' if $DEBUG && $VERBOSE
    end
    if options[:might_be_colon]
      # do processing in-line <sigh>
      total = (memory_bitmap.scan(/\x00{5}+/)).length
      if total >= 3 # really should be 4 for VLC
        # it had some darkness...therefore have been a colon!
        CACHE[memory_bitmap] = ":"
        return ":"
      end
    end
    image = MiniMagick::Image.from_blob(memory_bitmap)
    # any operation on image is expensive, requires convert.exe in path...
    if options[:should_invert] 
      # hulu wants negate
      # but doesn't want sharpen, for whatever reason...
      # mogrify calls it negate...
      image.negate 
    end

    image.format(:pnm)
    image.sharpen(2) if options[:sharpen] # hulu does *not* want sharpen, though I haven't checked it too closely...

    previous = nil
    p options if $DEBUG
    raise 'you must pass in OCR levels in the player description' unless options[:levels]
    for level in options[:levels]
      a = `#{GOCR} -l #{level} #{image.path} 2>NUL`
      if a =~ /[0-9]/
        # it can be like "_1_\n"
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
  
  extend self
  
end