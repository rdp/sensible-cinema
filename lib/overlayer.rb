require 'sane'

class Time
  def self.now_f
    now.to_f
  end
end

class OverLayer
  
  def nir(command)
    assert system(File.dirname(__FILE__) + "/../nircmd/nircmd " + command)
  end
  
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
  
  def initialize all_sequences
    mutes = all_sequences[:mutes]
    @mutes = mutes.to_a.sort!
    @am_muted = false # lodo...be more accurate here?
  end
  
  # returns seconds it's going...
  def cur_time
    return Time.now_f - @start_time
  end
    

  def continue_thread start_time_seconds
    Thread.new { continue start_time_seconds }
  end
  
  def continue start_time_seconds
    @mutes_index = 0
    @start_time = Time.now_f - start_time_seconds
    while next_mute = @mutes[@mutes_index]
      
      next_mute_absolute_start, next_mute_absolute_end = next_mute
      cur_time = Time.now_f - @start_time
      end_mute = @start_time + next_mute_absolute_end
      # we should sleep until the next start...
      time_till_next_mute = next_mute_absolute_start - cur_time
      pps 'sleeping till next mute:', time_till_next_mute , 's', 'which would be till second', Time.now_f + time_till_next_mute
      sleep time_till_next_mute if time_till_next_mute > 0
      pps 'woke up for next muting at', Time.now_f
      something_has_probably_changed end_mute
      @mutes_index += 1
    end
    
  end
  
  def something_has_probably_changed end_mute
      # may have been woken up early...
      mute!
      pps 'done starting mute at', Time.now_f
      duration = end_mute - Time.now_f
      sleep duration if duration > 0
      pps 'done sleeping muted which was duration', duration, 'unmuting now'
      unmute!
  end
  
end