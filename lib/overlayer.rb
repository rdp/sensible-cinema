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
    #nir("mutesysvolume 1")
  end
  
  def unmute!
    @am_muted = false
    #nir("mutesysvolume 0")
  end
  
  def initialize all_sequences#, start_time_seconds = 0
    mutes = all_sequences[:mutes]
    @mutes = mutes.to_a.sort!
    @am_muted = false
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @start_time = Time.now_f # assume now...
  end
  
  # returns seconds it's at...
  def cur_time
    return Time.now_f - @start_time
  end
  
  # sets it to a new set of seconds...
  def set_seconds seconds
    @mutex.synchronize {
      @start_time = Time.now_f - seconds
      pp 'start time is', @start_time
      @cv.signal # tell the driver thread to continue onward. Cheery-o. We're not super thread friendly but just for two...
    }
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
  
  # lodo: reject overlappings at all...
  
  def get_next_mute
    cur = cur_time
    for start, endy in @mutes
      if cur < endy
        return [start, endy]
      end
    end
    if @mutes[-1][1] <= cur
      :done
    else
      raise 'unexpected...'
    end
  end
  
  require 'timeout'
  
  def continue_until_past_all_mutes # lodo shouldn't it basically continue forever?
    @mutex.synchronize {
      loop {
        start, endy = get_next_mute
        return if start == :done
        time_till_next_mute_starts = start - cur_time
        pps 'sleeping till next mute:', time_till_next_mute_starts , 's'
        
        begin
          Timeout::timeout(time_till_next_mute_starts) {
            @cv.wait(@mutex)
          }
        rescue Timeout::Error
          # normal
        end
        pps 'woke up at', Time.now_f
        something_has_possibly_changed
      }
    }
    
  end
  
  def something_has_possibly_changed
    current = cur_time
    start, endy = get_next_mute
    return if start == :done
    if(current >= start && current < endy)
      mute!
      pps 'done starting mute at', Time.now_f
      duration_left = endy - current
      if duration_left > 0
        begin
        Timeout::timeout(duration_left) {
          @cv.wait(@mutex)
        }
        rescue Timeout::Error
          # normal
        end
      end
      pps 'done sleeping muted unmuting now'
      unmute! # lodo if they skip straight to another mute sequence, never unmute... hmm...
    end
  end
  
end