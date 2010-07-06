require 'sane'
require 'thread'
require 'timeout'

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
  
  def self.new_yaml yaml    
    OverLayer.new YAML.load(yaml)
  end
  
  # returns seconds it's at...
  def cur_time
    return Time.now_f - @start_time
  end
  
  def status
    if @am_muted
      "muted"
    else
      start, endy = get_next_mute
      if start == :done
        "no more"
      else
       "next mute in %.1fs" % (start - cur_time)
      end
    end + " (MmSsTt) " 
  end

  def keyboard_input char
    delta = case char
      when 'M' then 60
      when 'm' then -60
      when 'S' then 1
      when 's' then -1
      when 'T' then 0.1
      when 't' then -0.1
      else nil
     end
    if delta
      set_seconds(cur_time + delta)
    else
      puts 'invalid char:' + char
    end
  end
  
  # sets it to a new set of seconds...
  def set_seconds seconds
    @mutex.synchronize {
      @start_time = Time.now_f - seconds
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

  def start_thread continue_forever = false
    Thread.new { continue_until_past_all_mutes continue_forever }
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
  
  def continue_until_past_all_mutes continue_forever
    @mutex.synchronize {
      loop {
        start, endy = get_next_mute
        if start == :done
          return unless continue_forever
          time_till_next_mute_starts = 1_000_000
        else
          time_till_next_mute_starts = start - cur_time
        end
        pps 'sleeping unmuted until next mute begins in', time_till_next_mute_starts , 's from', Time.now_f if $VERBOSE
        
        begin
          Timeout::timeout(time_till_next_mute_starts) {
            @cv.wait(@mutex)
          }
        rescue Timeout::Error
          # normal
        end
        pps 'woke up at', Time.now_f if $VERBOSE
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
      pps 'just muted it at', Time.now_f if $VERBOSE
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
      pps 'done sleeping muted unmuting now', Time.now_f if $VERBOSE
      unmute! # lodo if they skip straight to another mute sequence, never unmute... hmm...
    end
  end
  
end
