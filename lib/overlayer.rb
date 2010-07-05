require 'sane'

module OverLayer
  
  def nir(command)
    assert system(File.dirname(__FILE__) + "/../nircmd/nircmd " + command)
  end
  
  def mute!
    puts 'muting'
    nir("mutesysvolume 1")
  end
  
  def unmute!
    puts 'unmuting'
    nir("mutesysvolume 0")
  end
  
  # allow for OverLayer.mute!
  extend self
  
end