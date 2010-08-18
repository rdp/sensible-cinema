puts 'warning--using fake blanker'

class Blanker 
  
  def self.startup
  end
  def self.shutdown
  end
  
  def self.blank_full_screen! text
      puts 'the screen is now...blank!'
  end
  
  def self.unblank_full_screen!
      puts 'the screen is now...visible!'
  end
  
end