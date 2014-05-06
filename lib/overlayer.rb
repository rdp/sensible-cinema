=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'sane'
require 'thread'
if RUBY_VERSION < '1.9.2' && !OS.jruby?
  raise 'need 1.9.2+ for MRI for the mutex #wait method'
end
require 'timeout'
require 'yaml'
require_relative 'muter'
require_relative 'blanker'
require_relative 'edl_parser'
require 'json'
require 'pp' # for pretty_inspect
require 'gui/dependencies.rb'

class OverLayer

  def initialize url
    @url = url
    @am_muted = false
    @am_blanked = false
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @file_mtime = nil
    reload_yaml!
    @just_unblanked = false
    @start_time = Time.now_f # assume they want to start immediately...
  end
    
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
  
  attr_accessor :all_sequences
  
  def reload_yaml!
    @all_sequences = OverLayer.translate_url @url
    puts '(re) loaded mute sequences from ' + @url + ' as', pretty_sequences.pretty_inspect, "" unless defined?($AM_IN_UNIT_TEST)
    signal_change
  end  
  
  def pretty_sequences
    new_sequences = {}
    @all_sequences.each{|type, values|
      if values.is_a? Array
	    # assume it's some tiemstamps :)
        new_sequences[type] = values.map{|s, f|
          [EdlParser.translate_time_to_human_readable(s), EdlParser.translate_time_to_human_readable(f)]
        }
      else
        new_sequences[type] = values
      end
    }
    new_sequences
  end
  

  
  EditTypes = ['Mutes', 'Skips'] 
  
  def self.translate_url url
    string = SensibleSwing::MainWindow.download_to_string url
	  if string.empty?
     raise "bad url? #{url}"
    end	   
	
    all = JSON.parse(string)    
    # now it's like {Mutes => {"1:02.0" => "1:3.0"}}
    # translate to all floats like {62.0 => 63.0}

    for type in EditTypes
      maps = all[type] || {}
      new = {}
      maps.each{ |full_edit|
        # both are like "1:02.0"
        start = full_edit['Start']
        endy = full_edit['End']
        start2 = EdlParser.translate_string_to_seconds(start) if start.present?
        endy2 = EdlParser.translate_string_to_seconds(endy) if endy.present?
        if !start2 || !endy2
          p "warning--possible error in the Edit Decision List file some line has start #{start2} or not end #{endy2}!" unless $AM_IN_UNIT_TEST
          # and drop it into the bitbucket...
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
  
  # returns seconds it's at currently...
  def cur_time
    Time.now_f - @start_time
  end
  
  def cur_english_time
    EdlParser.translate_time_to_human_readable(cur_time)
  end
  
  def status
    time = cur_english_time
    begin
      mute, blank, next_sig = get_current_state
      if next_sig == :done
        state = " no more after this point..."
      else
        state = " next will be at #{EdlParser.translate_time_to_human_readable next_sig}s "
      end
      if blank? or muted?
        state += "(" + [muted? ? "muted" : nil, blank? ? "blanked" : nil ].compact.join(' ') + ") "
      end
    end
    reload_yaml!
    time + state
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
    @thread = Thread.new { 
	  continue_until_past_all continue_forever 
	}
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
    for type in EditTypes do
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
      mute! # mute with blanks currently...
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
