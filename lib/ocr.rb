require 'mini_magick'
require 'open3'

module OCR
  
  GOCR = File.expand_path(File.dirname(__FILE__) + "/../vendor/gocr048.exe -C 0-9: -l 120")
  
  # options: :might_be_colon, :should_invert
  def identify_digit memory_bitmap, options = {}
    might_be_colon = options[:might_be_colon]
    should_invert = options[:should_invert]
    if might_be_colon
      # do processing in-line <sigh>
      total = (memory_bitmap.scan /\x00{5}+/).length
      if total >= 3 # really should be 4 for VLC
        # it had some dots...must have been a colon!
      end
      return ":"
    end
    image = MiniMagick::Image.from_blob(memory_bitmap)
    image.format(:pnm) # expensive, requires convert.exe in path...
    if should_invert # mogrify calls it negate...
      image.negate 
      p 'negating'
    end
    input, output, error, thread_if_on_19 = Open3.popen3 GOCR + " -"
    input.write image.to_blob
    input.close
    a = output.read
    output.close
    a.strip!
    a = "0" if a == ""
    a
  end
  
  def version
    `#{GOCR} -h 2>&1`
  end
  
  extend self
  
end