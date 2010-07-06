require 'sane'

class Time
  def self.now_f
    now.to_f
  end
end

module OverLayer
  
  def nir(command)
    assert system(File.dirname(__FILE__) + "/../nircmd/nircmd " + command)
  end
  
  @am_muted = false
  def am_muted?
    @am_muted
  end
  
  def mute!
    @am_muted = true
    nir("mutesysvolume 1")
  end
  
  def unmute!
    @am_muted = false
    nir("mutesysvolume 0")
  end
  
  def overlay sequences, start_time_seconds = 0.0
    mutes = sequences[:mutes]
    mutes = mutes.to_a.sort!
    start_time = Time.now_f # - start_time_seconds
    while next_mute = mutes.shift
      next_mute_absolute_start, next_mute_absolute_end = next_mute
      cur_time = Time.now_f - start_time
      end_mute = start_time + next_mute_absolute_end
      # we should sleep until the next start...
      time_till_next_mute = next_mute_absolute_start - cur_time
      pps 'sleeping', time_till_next_mute , 's'
      sleep time_till_next_mute if time_till_next_mute > 0
      mute!
      duration = end_mute - Time.now_f
      sleep duration if duration > 0
      pps 'done sleeping', duration
      unmute!
    end
    
  end
  
  # allow for OverLayer.mute! et al
  extend self
  
end