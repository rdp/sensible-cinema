require 'sane'
require 'thread'

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
  
  def initialize all_sequences#, start_time_seconds = 0
    mutes = all_sequences[:mutes]
    @mutes = mutes.to_a.sort!
    @am_muted = false
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @start_time = Time.now_f # assume now...
  end
  
  # returns seconds it's going...
  def cur_time
    return Time.now_f - @start_time
  end
    
  # I want two drivers...
  # one a thread here, that can be woken up (?)
  # I want the equivalent of EM, like...
  # state and it gets called into by two things
  # the key controller,
  # and the pause driver.
  # key controller -> pause driver...it needs mutex with 
  # with EM it's like receiving a new packet
  # condition variable...hmm...
  # in reality we have a scheduler...hmm...
  # maybe a sub-project...hmm...
  # something like
  # def restart new_time
  #  @start_time = x
  #  broadcast
  # end

  def start_thread
    Thread.new { continue_until_past_all_mutes }
  end
  
  DONE = 'done'
  
  # lodo: reject overlappings at all...
  
  def get_next_mute
    cur = cur_time
    for start, endy in @mutes
      if cur < endy
        return [start, endy]
      end
    end
    if @mutes[-1][1] < cur
      DONE
    else
      nil
    end
  end
  
  def continue_until_past_all_mutes # lodo shouldn't it basically continue forever?
    @mutex.synchronize {
      start, endy = get_next_mute
      return if start == DONE
      time_till_next_mute_starts = start - cur_time
      pps 'sleeping till next mute:', time_till_next_mute_starts , 's'
      sleep time_till_next_mute_starts
        #@cv.wait()
      pps 'woke up for next muting at', Time.now_f
      something_has_probably_changed endy
    }
    
  end
  
  def something_has_probably_changed end_mute
      # may have been woken up early...
      mute!
      pps 'done starting mute at', Time.now_f
      duration = end_mute - cur_time
      sleep duration if duration > 0
      pps 'done sleeping muted which was duration', duration, 'unmuting now'
      unmute!
  end
  
end