require 'mini_magick'
require 'open3'

module OCR
  
  GOCR = File.expand_path(File.dirname(__FILE__) + "/../vendor/gocr048.exe")
  
  def identify_digit memory_bitmap
    image = MiniMagick::Image.from_blob(memory_bitmap)
    image.format(:pnm) # expensive, requires convert.exe in path...
    input, output, error, thread_if_on_19 = Open3.popen3 GOCR + " -"
    input.write image.to_blob
    input.close
    a = output.read
    output.close
    a
  end
  
  def version
    `#{GOCR} -h 2>&1`
  end
  
  
  extend self
  
  
end