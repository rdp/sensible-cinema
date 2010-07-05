require 'sane'

module OverLayer
  
  def nir(command)
    assert system(File.dirname(__FILE__) + "/../nircmd/nircmd " + command)
  end
  
  def mute!
    nir("mutesysvolume 1")
  end
  
  def unmute!
    nir("mutesysvolume 0")
  end
  
  # allow for OverLayer.mute!
  extend self
  
end