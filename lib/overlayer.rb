require 'sane'
require 'thread'
require 'timeout'
require 'yaml'
require_relative 'muter'
require_relative 'blanker'
require 'pp' # pretty_inspect

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
    Muter.mute! unless $DEBUG
  end
  
  def unmute!
    @am_muted = false
    puts 'unmuting!' if $VERBOSE
    Muter.unmute! unless $DEBUG
  end
  
  def blank!
    @am_blanked = true
    Blanker.blank_full_screen! unless $DEBUG
  end
  
  def unblank!
    @am_blanked = false
    Blanker.unblank_full_screen! unless $DEBUG
  end
  
  def reload_yaml!
    current_mtime = File.stat(@filename).mtime # save 0.0002!
    if @file_mtime != current_mtime
      @all_sequences = OverLayer.translate_yaml(File.read(@filename))
      # LTODO... @all_sequences = @all_sequences.map{|k, v| v.sort!} etc. and validate...
      puts '(re) loaded mute sequences from ' + File.basename(@filename) + ' as', pretty_sequences.pretty_inspect, "" unless $DEBUG # I hate these during unit tests...
      @file_mtime = current_mtime 
      signal_change
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
    begin
      all = YAML.load(raw_yaml) || {}
      
    rescue NoMethodError
      p 'appears your file has a syntax error in it--perhaps missing quotation marks'
      return
    end
    # now it's like {:mutes => {"1:02.0" => "1:3.0"}}
    # translate to floats like 62.0 => 63.0
    for type in [:mutes, :blank_outs]
      maps = all[type] || all[type.to_s] || {}
      new = {}
      maps.each{|start,endy|
        # both are like 1:02.0
        start = translate_string_to_seconds(start)
        endy = translate_string_to_seconds(endy)
        if start == 0 || endy == 0
          p 'warning--possible error in the scene list someline not parsed! (NB if you want one to start at time 0 please use 0.0001)', start, endy unless $DEBUG
          # drop it in bitbucket...
        else
          new[start] = endy
        end
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
  
  def timestamp_changed to_this_exact_string_might_be_nil, delta
    set_seconds OverLayer.translate_string_to_seconds(to_this_exact_string_might_be_nil) + delta if to_this_exact_string_might_be_nil
  end
  
  def self.translate_string_to_seconds s
    # might actually already be a float, or int, depending on the yaml
    # int for 8 => 9 and also for 1:09 => 1:10
    if s.is_a? Numeric
      return s.to_f
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
    Time.now_f - @start_time
  end
  
  def cur_english_time
    translate_time_to_human_readable(cur_time)
  end
  
  def status
    time = "Current time: " + cur_english_time
    begin
      mute, blank, next_sig = get_current_state
      if next_sig == :done
        state = " no more actions after this point..."
      else
        state = " next action at #{translate_time_to_human_readable next_sig}s "
      end
      state += "(#{mute ? "muted" : '' } #{blank ? "blanked" : '' })"
    end
    reload_yaml!
    time + state + " (HhMmSsTtdvq): "
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
      when 'v' then
        $VERBOSE = !$VERBOSE
        p 'set verbose to ', $VERBOSE
        return
      when 'd'
        $DEBUG = !$DEBUG
        p 'set debug to', $DEBUG
        return
      when ' ' then
        puts cur_time
        return
      else nil
    end
    if delta
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
    }
    signal_change
  end
  
  def signal_change
    @mutex.synchronize {
      # tell the driver thread to wake up and re-check state. 
      # We're not super thread friendly but good enough for having two contact each other...
      @cv.signal
    }
  end

  # we have a single scheduler thread, that is notified when the time may have changed
  # like 
  # def restart new_time
  #  @current_time = xxx
  #  broadcast # things have changed
  # end

  def start_thread continue_forever = false
    @thread = Thread.new { continue_until_past_all continue_forever }
  end
  
  def kill_thread!
    @thread.kill
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
    if RUBY_VERSION < '1.9.2'
      raise 'need 1.9.2+ for MRI for the mutex stuff' unless RUBY_PLATFORM =~ /java/
    end

    @mutex.synchronize {
      loop {
        muted, blanked, next_point = get_current_state
        if next_point == :done
          if continue_forever
            time_till_next_mute_starts = 1_000_000
          else
            return
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
      puts '','muted at ' + cur_english_time unless $DEBUG # too chatty
    end
    
    if !should_be_muted && muted?
      unmute!
      puts '','unmuted at ' + cur_english_time unless $DEBUG
    end
    
    if should_be_blank && !blank?
      blank!
      puts '','blanked at ' + cur_english_time
    end

    if !should_be_blank && blank?
      unblank!
      puts '','unblanked at ' + cur_english_time
    end
    
  end
  
  def something_has_possibly_changed
    current = cur_time
    muted, blanked, next_point = get_current_state
    endy = next_point
    return if next_point == :done
    set_states!
    duration_left = endy - current
    pps 'just muted it at', Time.now_f, current, 'for interval:', 'which is', duration_left, 'more s' if $VERBOSE
    if duration_left > 0
      @cv.wait(@mutex, duration_left) if duration_left > 0
    end
    pps 'done sleeping', duration_left, 'was muted unmuting now', Time.now_f if $VERBOSE
    set_states!
  end
  
end
