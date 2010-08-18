im_path = File.expand_path(File.dirname(__FILE__) + "/../vendor/imagemagick") # convert.exe wants to only be chosen from here...
ENV['PATH'] = im_path + ';' + ENV['PATH']

require 'mini_magick'

# helper for OCR'ing single digits that were screen captured
module OCR
  
  GOCR = File.expand_path(File.dirname(__FILE__) + "/../vendor/gocr048.exe -C lC0-9:/S ")
  
  CACHE = {}
  
  # options are :might_be_colon, :should_invert
  def identify_digit memory_bitmap, options = {}
    if CACHE[memory_bitmap]
      return CACHE[memory_bitmap] unless defined?($OCR_NO_CACHE)
    end
    if options[:might_be_colon]
      # do processing in-line <sigh>
      total = (memory_bitmap.scan /\x00{5}+/).length
      if total >= 3 # really should be 4 for VLC
        # it had some darkness...therefore have been a colon!
        CACHE[memory_bitmap] = ":"
        return ":"
      end
    end
    image = MiniMagick::Image.from_blob(memory_bitmap)
    image.format(:pnm) # expensive, requires convert.exe in path...
    if options[:should_invert] 
      # mogrify calls it negate...
      image.negate 
    end
    for level in [130, 100, 0, 200] # 130 for vlc, 100 for hulu, 0, 200 for youtube yikes
      a = `#{GOCR} -l #{level} #{image.path} 2>NUL`
      # a is now "_1_\n"
      a.strip!
      a.gsub!('_', '')
      a = '3' if a == 'S' # sigh
      a = '0' if a =~ /C/ # sigh again
      a = '4' if a =~ /l/ # sigh
      if a =~ /[0-9]/
        a = a.to_i
        CACHE[memory_bitmap] = a
        return a
      end
    end
    nil
  end
  
  def version
    `#{GOCR} -h 2>&1`
  end
  
  extend self
  
end