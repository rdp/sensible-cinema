require 'java'

require 'sane'

module SensibleSwing
  
  class MainWindow < javax.swing.JFrame
    
    def self.download full_url, to_here
      require 'open-uri'
      require 'openssl'
      eval("OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE") if full_url =~ /https/
      writeOut = open(to_here, "wb")
      writeOut.write(open(full_url).read)
      writeOut.close
    end
    
    def self.download_to_string full_url
       require 'tempfile'
       to = Tempfile.new 'abc'
       download(full_url, to.path)
       out = File.binread(to.path)
       to.delete
       out
    end
    
  end
end