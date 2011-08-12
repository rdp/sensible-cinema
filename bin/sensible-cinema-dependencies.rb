require 'java'

module SensibleSwing
  
  class MainWindow < javax.swing.JFrame
    def self.download full_url, to_here
      require 'open-uri'
      writeOut = open(to_here, "wb")
      writeOut.write(open(full_url).read)
      writeOut.close
    end
  end
end