require 'sane'
require 'thread'
require 'timeout'
require 'yaml'
require_relative 'muter'
require_relative 'blanker'
require 'pp'

class Time
  def self.now_f
    now.to_f
  end
end

class OverLayer
  
  def muted?
    @am_muted
  end
  
  def blank?
    @am_blanked
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
  
  def blank!
    @am_blanked = true
    Blanker.blank_full_screen! unless $TEST
  end
  
  def unblank!
    @am_blanked = false
    Blanker.unblank_full_screen! unless $TEST
  end
  
  def reload_yaml!
    if @file_mtime != (new_time = File.stat(@filename).mtime)
      @all_sequences = OverLayer.translate_yaml(File.read(@filename))
      # LTODO @all_sequences = @all_sequences.map{|k, v| v.sort!} 
      puts '(re) loaded mute sequences as', pretty_sequences.pretty_inspect, "" unless $TEST
      pps 'because old time', @file_mtime.to_f, '!= new time', new_time.to_f if $VERBOSE
      @file_mtime = new_time # save 0.0002!
    else
      p 'matching time:', new_time if $VERBOSE
    end
  end
  
  def pretty_sequences
    new_sequences = {}
    @all_sequences.each{|type, values|
      if values.is_a? Array
        new_sequences[type] = values.map{|s, f|
          [translate_time_to_human_readable(s), translate_time_to_human_readable(f)]
        }
      else
        new_sequences[type] = values
      end
    }
    new_sequences
  end
  
  def self.new_raw ruby_hash
    File.write 'temp.yml', YAML.dump(ruby_hash)
    OverLayer.new('temp.yml')
  end
  
  def initialize filename, minutes = nil 
    @filename = filename
    @am_muted = false
    @am_blanked = false
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @file_mtime = nil
    reload_yaml!
    @start_time = Time.now_f # assume they want to start immediately...
    if minutes
      self.set_seconds self.class.translate_string_to_seconds(minutes)
    end
  end
  
  def self.translate_yaml raw_yaml
    all = YAML.load(raw_yaml)
    # now it's like {:mutes => {"1:02.0" => "1:3.0"}}
    # translate to floats like 62.0 => 63.0
    for type in [:mutes, :blank_outs]
      maps = all[type] || all[type.to_s] || {}
      new = {}
      maps.each{|s,e|
        # both are like 1:02.0
        new[translate_string_to_seconds(s)] = translate_string_to_seconds(e)
      }
      all.delete(type.to_s)
      all[type] = new.sort
    end
    all
  end
  
  def translate_time_to_human_readable seconds
    # 3600 => "1:00:00"
    out = ''
    hours = seconds.to_i / 3600
    out << "%d" % hours 
    out << ":"
    seconds = seconds - hours*3600
    minutes = seconds.to_i / 60
    out << "%02d" % minutes
    seconds = seconds - minutes * 60
    out << ":"
    out << "%04.1f" % seconds
  end
    
  
  def timestamp_changed
    # round cur_time to
    current_time = cur_time
    better_time = current_time.round
    set_seconds better_time
    puts 'screen snapshot diff with time we thought it was was:' + (current_time - better_time).to_s if $VERBOSE
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
    time = "Current time: " + translate_time_to_human_readable(cur_time)
    begin
      mute, blank, next_sig = get_current_state
      if next_sig == :done
        state = " no more actions after this point..."
      else
        state = " next action at #{translate_time_to_human_readable next_sig}s (#{mute ? "muted" : '' } #{blank ? "blanked" : '' })"
      end
    end
    time + state + " (HhMmSsTtq): "
  end

  def keyboard_input char
    delta = case char
      when 'h' then 60*60
      when 'H' then -60*60
      when 'm' then 60
      when 'M' then -60
      when 's' then 1
      when 'S' then -1
      when 't' then 0.1
      when 'T' then -0.1
      when ' ' then
        puts cur_time; return
      else nil
    end
    if delta
      reload_yaml!
      set_seconds(cur_time + delta)
    else
      puts 'invalid char: [' + char + ']'
    end
  end
  
  # sets it to a new set of seconds...
  def set_seconds seconds
    seconds = [seconds, 0].max
    @mutex.synchronize {
      @start_time = Time.now_f - seconds
      @cv.signal # tell the driver thread to continue onward. Cheery-o. We're not super thread friendly but good enough for having two contact each other...
    }
  end

  # we have a single scheduler thread, that is notified when the time may have changed
  # like 
  # def restart new_time
  #  @current_time = xxx
  #  broadcast # things have changed
  # end

  def start_thread continue_forever = false
    Thread.new { continue_until_past_all continue_forever }
  end
  
  # returns [start, end, active|:done]
  def discover_state type, cur_time
      for start, endy in @all_sequences[type]
        if cur_time < endy
          # first one that we haven't passed the *end* of yet
          if(cur_time >= start)
            return [start, endy, true]
          else
            return [start, endy, false]
          end
        end
        
      end
      return [nil, nil, :done]
  end
  
  # returns [true, false, next_moment_of_importance|:done]
  def get_current_state
    all = []
    time = cur_time
    for type in [:mutes, :blank_outs] do
      all << discover_state(type, time)
    end
    output = []
    # all is [[start, end, active]...] or [:done, :done]
    # so create [true, false, next_moment]
    earliest_moment = 1_000_000
    all.each{|start, endy, active|
      if active == :done
        output << false
        next
      else
        output << active
      end
      if active
        earliest_moment = [earliest_moment, endy].min
      else
        earliest_moment = [earliest_moment, start].min
      end
    }
    if earliest_moment == 1_000_000
      output << :done
    else
      output << earliest_moment
    end
    output
  end
  
  def continue_until_past_all continue_forever
    @mutex.synchronize {
      loop {
        muted, blanked, next_point = get_current_state
        if next_point == :done
          unless continue_forever
            return # done!
          else
            time_till_next_mute_starts = 1_000_000
          end
        else
          time_till_next_mute_starts = next_point - cur_time
        end
        
        pps 'sleeping until next action (%s) begins in %fs (%f) %f' % [next_point, time_till_next_mute_starts, Time.now_f, cur_time] if $VERBOSE
        
        @cv.wait(@mutex, time_till_next_mute_starts) if time_till_next_mute_starts > 0
        pps 'just woke up from pre-mute wait at', Time.now_f if $VERBOSE
        something_has_possibly_changed
      }
    }
  end  
  
  def set_states!
    should_be_muted, should_be_blank, next_point = get_current_state
    
    if should_be_muted && !muted?
      mute!
    end
    
    if !should_be_muted && muted?
      unmute!
    end
    
    if should_be_blank && !blank?
      blank!
    end

    if !should_be_blank && blank?
      unblank!
    end
    
  end
  
  def something_has_possibly_changed
    current = cur_time
    muted, blanked, next_point = get_current_state
    @muted = muted
    @blanked = blanked
    @endy = next_point
    return if next_point == :done
    if(current < next_point)
      set_states!
      duration_left = @endy - current
      pps 'just muted it at', Time.now_f, current, 'for interval:', 'which is', duration_left, 'more s' if $VERBOSE
      if duration_left > 0
        @cv.wait(@mutex, duration_left) if duration_left > 0
      end
      pps 'done sleeping', duration_left, 'was muted unmuting now', Time.now_f if $VERBOSE
      set_states!
    end
  end
  
end
