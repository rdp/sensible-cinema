require 'sane'
require 'thread'
require 'timeout'
require 'yaml'

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
    nir("mutesysvolume 1") unless defined?($TEST)
  end
  
  def unmute!
    @am_muted = false
    nir("mutesysvolume 0") unless defined?($TEST)
  end
  
  def initialize filename, all_sequences = nil
    @filename = filename
    all_sequences ||= OverLayer.translate_yaml(File.read filename)
    mutes = all_sequences[:mutes]
    @mutes = mutes.to_a.sort!
    @am_muted = false
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @start_time = Time.now_f # assume now...
  end
  
  def self.translate_yaml raw_yaml
    all = YAML.load(raw_yaml)
    # now it's like {:mutes => {"1:2.0" => "1:3.0"}}
    mutes = all[:mutes]
    new_mutes = {}
    mutes.each{|s,e|
      # both are like 1:02.0
      new_mutes[translate_string_to_seconds(s)] = translate_string_to_seconds(e)
    }
    all[:mutes] = new_mutes
    all
  end
  
  def self.translate_string_to_seconds s
    # might actually already be a float...
    if s.is_a? Float
      return s
    end
    
    # s is like 1:01:02.0
    total = 0.0
    seconds = s.split(":")[-1]
    total += seconds.to_f
    minutes = s.split(":")[-2] || "0"
    total += 60 * minutes.to_i
    hours = s.split(":")[-3] || "0"
    total += 60* 60 * hours.to_i
    total
  end
  
  # returns seconds it's at currently...
  def cur_time
    return Time.now_f - @start_time
  end
  
  def status
    start, endy = get_next_mute
    if @am_muted
      "muted (%.1fs - %.1fs)" % [start, endy]
    else
      if start == :done
        "no more mutes"
      else
        "next mute in %.1fs (%.1fs - %.1fs)" % [(start - cur_time),start, endy]
      end
    end + " (MmSsTt): "
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
      duration_left = endy - current
      pps 'just muted it at', Time.now_f, current, 'for interval:', start, '-', endy, 'which is', duration_left, 'more s' if $VERBOSE
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
