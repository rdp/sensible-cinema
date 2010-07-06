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
  
  def overlay sequences, total_time = nil
    mutes = sequences[:mutes]
    mutes = mutes.to_a.sort!
    start_time = Time.now
    while next_mute = mutes.shift
      next_mute_absolute_start, next_mute_absolute_end = next_mute
      cur_time = Time.now - start_time
      end_mute = start_time + next_mute_absolute_end
      # we should sleep until the next start...
      time_till_next_mute = next_mute_absolute_start - cur_time
      pps 'doing next:', next_mute.inspect, 'with cur', cur_time, Time.now_f, 'end time:', end_mute.to_f, 'time till next:', time_till_next_mute 
      sleep time_till_next_mute
      pps 'muting @', Time.now.to_f
      mute!
      sleep end_mute - Time.now
      pps 'unmuting @', Time.now.to_f
      unmute!
    end
    
  end
  
  # allow for OverLayer.mute! et al
  extend self
  
end