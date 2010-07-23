require 'sane'
require 'thread'
require 'timeout'
require 'yaml'
require_relative 'muter'

class Time
  def self.now_f
    now.to_f
  end
end

if RUBY_VERSION < '1.9.2'
  raise 'need 1.9.2+ for MRI' unless RUBY_PLATFORM =~ /java/
end

class OverLayer
  
  def muted?
    @am_muted
  end
  
  def mute!
    @am_muted = true
    puts 'muting!' if $VERBOSE
    Muter.mute! unless defined?($TEST)
  end
  
  def unmute!
    @am_muted = false
    puts 'unmuting!' if $VERBOSE
    Muter.unmute! unless defined?($TEST)
  end

  def reload_yaml!
    if @file_mtime != (new_time = File.stat(@filename).mtime)
      all_sequences = OverLayer.translate_yaml(File.read(@filename))
      pp '(re) loaded mute sequences as ', all_sequences
      pp 'because old time', @file_mtime.to_f, '!= new time', new_time.to_f if $VERBOSE
      mutes = all_sequences[:mutes]
      @mutes = mutes.to_a.sort!
      # File.stat takes 0.0002 so we're probably ok doing two of them.
      @file_mtime = new_time
    end
  end
  
  def initialize filename
    @filename = filename
    @am_muted = false
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @file_mtime = nil
    reload_yaml!
    @start_time = Time.now_f # assume they want to start immediately...
  end
  
  def self.translate_yaml raw_yaml
    all = YAML.load(raw_yaml)
    # now it's like {:mutes => {"1:02.0" => "1:3.0"}}
    # translate to floats like 62.0 => 63.0
    for type in [:mutes, :blank_outs]
      mutes = all[type] || {}
      new = {}
      mutes.each{|s,e|
        # both are like 1:02.0
        new[translate_string_to_seconds(s)] = translate_string_to_seconds(e)
      }
      all[type] = new
    end
    all
  end
  
  def timestamp_changed
    # round cur_time to
    current_time = cur_time
    better_time = current_time.round
    set_seconds better_time
    puts 'timestamp delta was:' + (current_time - better_time).to_s if $VERBOSE
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
    if @am_muted
      "muted (%.1fs - %.1fs)" % [@start, @endy]
    else
      start, endy = get_next_mute
      if start == :done
        "no more mutes"
      else
        "next mute in %.1fs (%.1fs - %.1fs)" % [(start - cur_time),start, endy]
      end
    end + " (MmSsTtq): "
  end

  def keyboard_input char
    delta = case char
      when 'm' then 60
      when 'M' then -60
      when 's' then 1
      when 'S' then -1
      when 't' then 0.1
      when 'T' then -0.1
      else nil
    end
    if delta
      reload_yaml!
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
  # we have a single scheduler thread, that is notified when the time may have changed
  # like 
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
          unless continue_forever
            return
          end
          time_till_next_mute_starts = 1_000_000
        else
          time_till_next_mute_starts = start - cur_time
        end
        pps 'sleeping unmuted until next mute (%f - %f) begins in' % [start, endy], time_till_next_mute_starts , 's from', Time.now_f, cur_time if $VERBOSE
        
        @cv.wait(@mutex, time_till_next_mute_starts)
        pps 'just woke up from pre-mute pause at', Time.now_f if $VERBOSE
        something_has_possibly_changed
      }
    }
  end
  
  def something_has_possibly_changed
    current = cur_time
    start, endy = get_next_mute
    @start = start
    @endy = endy
    return if start == :done
    if(current >= start && current < endy)
      mute!
      duration_left = endy - current
      pps 'just muted it at', Time.now_f, current, 'for interval:', start, '-', endy, 'which is', duration_left, 'more s' if $VERBOSE
      if duration_left > 0
        @cv.wait(@mutex, duration_left)
      end
      pps 'done sleeping',duration_left, 'was muted unmuting now', Time.now_f if $VERBOSE
      unmute! # lodo if they skip straight to another mute sequence, never unmute... hmm...
    end
  end
  
end
