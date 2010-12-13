Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
    require 'sane'
require 'thread'
require 'timeout'
require 'yaml'
require_relative 'muter'
require_relative 'blanker'
require 'pp' # for pretty_inspect

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
    Muter.mute! unless defined?($AM_IN_UNIT_TEST)
  end
  
  def unmute!
    @am_muted = false
    puts 'unmuting!' if $VERBOSE
    Muter.unmute! unless defined?($AM_IN_UNIT_TEST)
  end
  
  def blank! seconds
    @am_blanked = true
    Blanker.blank_full_screen! seconds
  end
  
  def unblank!
    @just_unblanked = true
    @am_blanked = false
    Blanker.unblank_full_screen!
  end
  
  def check_reload_yaml
    current_mtime = File.stat(@filename).mtime
    if @file_mtime != current_mtime
      reload_yaml!
      @file_mtime = current_mtime 
    else
      #p 'same mtime:', @file_mtime if $DEBUG && $VERBOSE
    end
  end
  
  attr_accessor :all_sequences
  
  def reload_yaml!
    @all_sequences = OverLayer.translate_yaml(File.read(@filename))
    puts '(re) loaded mute sequences from ' + File.basename(@filename) + ' as', pretty_sequences.pretty_inspect, "" unless defined?($AM_IN_UNIT_TEST)
    signal_change
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
  
  def initialize filename
    @filename = filename
    @am_muted = false
    @am_blanked = false
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @file_mtime = nil
    check_reload_yaml
    @just_unblanked = false
    @start_time = Time.now_f # assume they want to start immediately...
  end
  
  def self.translate_yaml raw_yaml
    begin
      all = YAML.load(raw_yaml) || {}      
    rescue NoMethodError, ArgumentError
      p 'appears your file has a syntax error in it--perhaps missing quotation marks?'
      return
    end
    # now it's like {:mutes => {"1:02.0" => "1:3.0"}}
    # translate to floats like 62.0 => 63.0

    for type in [:mutes, :blank_outs]
      maps = all[type] || all[type.to_s] || {}
      new = {}
      maps.each{|start,endy|
        # both are like 1:02.0
        start2 = translate_string_to_seconds(start) if start
        endy2 = translate_string_to_seconds(endy) if endy
        if start2 == 0 || endy2 == 0 || start == nil || endy == nil
          p 'warning--possible error in the Edit Decision List file some line not parsed! (NB if you want one to start at time 0 please use 0.0001)', start, endy unless $AM_IN_UNIT_TEST
          # drop this line into the bitbucket...
          next
        end
        
        if start2 == endy2 || endy2 < start2
          p 'warning--found a line that had poor interval', start, endy, type unless defined?($AM_IN_UNIT_TEST)
          next
        end
        if(endy2 > 60*60*3)
          p 'warning--found setting past 3 hours [?]', start, endy, type unless defined?($AM_IN_UNIT_TEST)
        end
        new[start2] = endy2
      }
      all.delete(type.to_s) # cleanup
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
    if @just_unblanked
      # ignore it, since it was probably just caused by the screen blipping
      # at worse this will put us 1s behind...hmm.
      @just_unblanked = false
      p 'ignoring timestamp update ' + to_this_exact_string_might_be_nil.to_s if $VERBOSE
    else
      set_seconds OverLayer.translate_string_to_seconds(to_this_exact_string_might_be_nil) + delta if to_this_exact_string_might_be_nil
    end
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
    time = cur_english_time
    begin
      mute, blank, next_sig = get_current_state
      if next_sig == :done
        state = " no more after this point..."
      else
        state = " next will be at #{translate_time_to_human_readable next_sig}s "
      end
      if blank? or muted?
        state += "(" + [muted? ? "muted" : nil, blank? ? "blanked" : nil ].compact.join(' ') + ") "
      end
    end
    check_reload_yaml
    time + state + "(r [ctrl+c or q to quit]): "
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
      when 'q' then
        puts '','quitting'
        exit(1)        
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
        puts 'timestamp:' + cur_english_time
        return
      when 'r' then
        reload_yaml!
        puts
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
  
  #
  # returns [true, false, next_moment_of_importance|:done] ( true, false for if it should be currently muted, blanked )
  #
  def get_current_state
    all = []
    time = cur_time
    for type in [:mutes, :blank_outs] do
      all << discover_state(type, time)
    end
    output = []
    # all is [[start, end, active]...] or [:done, :done]
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
            #set_states! # for the unit tests' sake
            return
          end
        else
          time_till_next_mute_starts = next_point - cur_time
        end
        
       # pps 'sleeping until next action (%s) begins in %fs (%f) %f' % [next_point, time_till_next_mute_starts, Time.now_f, cur_time] if $VERBOSE
        
        @cv.wait(@mutex, time_till_next_mute_starts) if time_till_next_mute_starts > 0
        set_states!
      }
    }
  end  
  
  def display_change change
    puts '' unless defined?($AM_IN_UNIT_TEST)
    if $VERBOSE
      puts change + ' at ' + cur_english_time
    end    
  end
  
  def set_states!
    should_be_muted, should_be_blank, next_point = get_current_state
    
    if should_be_muted && !muted?
      mute!
      display_change 'muted'
    end
    
    if !should_be_muted && muted?
      unmute!      
      display_change 'unmuted'
    end
    
    if should_be_blank && !blank?
      blank! "%.02f" % (next_point - cur_time)
      display_change 'blanked'
    end

    if !should_be_blank && blank?
      unblank!
      display_change 'unblanked'
    end
    
  end
  
end

class Time
  def self.now_f
    now.to_f
  end
end
