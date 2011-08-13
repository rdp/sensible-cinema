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
class EdlParser

  EDL_DIR = File.expand_path(__DIR__  + "/../zamples/edit_decision_lists/dvds")
  
  if File::ALT_SEPARATOR
    EDL_DIR.gsub! File::SEPARATOR, File::ALT_SEPARATOR # to_filename...
  end

  # returns {"mutes" => [["00:00", "00:00", string1, string2, ...], ...], "blank_outs" -> [...], "url" => ...}  
  def self.parse_file filename
    output = parse_string File.read(filename), filename, []
    if relative = output["take_from_relative_file"]
      new_filename = File.dirname(filename) + '/' + relative
      new_input = parse_file new_filename
      output.merge! new_input
    end
    output
  end
  
  private
  
  # better eye-ball these before letting people run them, eh? TODO
  # but I couldn't think of any other way to parse the files tho
  def self.parse_string string, filename, ok_categories_array = []
    string = '{' + string + "\n}"
    if filename
     raw = eval(string, binding, filename)
    else
     raw = eval string
    end
    
    raise SyntaxError.new("maybe missing quotation marks?" + string) if raw.keys.contain?(nil)
    
    # mutes and blank_outs need to be special parsed into arrays...
    mutes = raw["mutes"] || []
    blanks = raw["blank_outs"] || []
    raw["mutes"] = convert_to_timestamp_arrays(mutes, ok_categories_array)
    raw["blank_outs"] = convert_to_timestamp_arrays(blanks, ok_categories_array)
    raw
  end
  
  # converts "blanks" => ["00:00:00", "00", "reason", "01", "01", "02", "02"] into sane arrays, also filters based on category, though disabled for production
  def self.convert_to_timestamp_arrays array, ok_categories_array
    out = []
    while(single_element = extract_entry!(array))
      # assume that it (could be, at least) start_time, end_time, category, number
      category = single_element[-2]
      category_number = single_element[-1]
      include = true
      if ok_categories_array.index([category, category_number])
       include = false
      elsif ok_categories_array.index([category])
       include = false
      elsif ok_categories_array.detect{|cat, setting| setting.is_a? Fixnum}
       for cat, setting in ok_categories_array
         if cat == category && setting.is_a?(Fixnum)
            # check for a number? 
            if category_number.to_i.to_s == category_number
              as_number = category_number.to_i
 p 'checking',as_number,setting
              if as_number < setting
                include = false
              end
            end
         end
       end

      end
      out << single_element if include
    end
    out
  end
  
  #TimeStamp = /(^\d+:\d\d[\d:\.]*$|\d+)/ # this one also allows for 4444 [?] and also weirdness like "don't kill the nice butterfly 2!" ...
  TimeStamp = /^\d+:\d\d[\d:\.]*$/
  # starts with a digit, has at least one colon followed by two digits,then some combo of digits and colons and periods...
  
  def self.extract_entry! from_this
    return nil if from_this.length == 0
    # two digits, then whatever else you see, that's not a digit...
    out = from_this.shift(2)
    out.each{|d|
      unless d =~ TimeStamp
        raise SyntaxError.new('non timestamp? ' + d) 
      end
    }
    while(from_this[0] && from_this[0] !~ TimeStamp)
      out << from_this.shift
    end
    out
  end
  
  def self.get_secs timestamp_string_begin, timestamp_string_end, add_begin, add_end, splits
    answers = []
    unless timestamp_string_begin
      raise 'non begin' 
    end
    unless timestamp_string_end
      raise 'non end' 
    end
    for type, offset, multiplier in [[timestamp_string_begin, add_begin, -1], [timestamp_string_end, add_end, 1]]
      original_secs = translate_string_to_seconds(type) + offset
      # now if splits is 900 and we'are at 909, then we're just 9
      closest_split_idx = splits.reverse.index{|t| t < original_secs}
      if closest_split_idx
        closest_split = splits.reverse[closest_split_idx]
        # add some extra seconds onto these if they're "past" a split, too
        original_secs = original_secs - closest_split + multiplier * (splits.length - closest_split_idx)
        original_secs = [0, original_secs].max # no negatives allowed :)
      end
      answers << original_secs
    end
    answers
  end
  
  public 
  
  # divides up mutes and blanks so that they don't overlap, preferring blanks over mutes
  # returns it like [[start,end,type], [s,e,t]...] type like either :blank and :mute
  # [[70.0, 73.0, :blank], [378.0, 379.1, :mute]]
  def self.convert_incoming_to_split_sectors incoming, add_this_to_all_ends = 0, subtract_this_from_beginnings = 0, splits = []
    raise if subtract_this_from_beginnings < 0
    raise if add_this_to_all_ends < 0
    if splits != []
      # allow it to do all the double checks we later skip, just in case :)
      self.convert_incoming_to_split_sectors incoming
    end
    mutes = incoming["mutes"] || {}
    blanks = incoming["blank_outs"] || {}
    mutes = mutes.map{|k, v| get_secs(k, v, -subtract_this_from_beginnings, add_this_to_all_ends, splits) + [:mute]}
    blanks = blanks.map{|k, v| get_secs(k, v, -subtract_this_from_beginnings, add_this_to_all_ends, splits) + [:blank]}
    combined = (mutes+blanks).sort
    
    # detect overlap...
    previous = nil
    combined.each_with_index{|current, idx|
      s,e,t = current
      if e < s
       raise SyntaxError.new("detected an end before a start: #{e} < #{s}") if e < s unless splits.length > 0
      end
      if previous
        ps, pe, pt = previous
        if (s < pe)
          raise SyntaxError.new("detected an overlap #{[s,e,t].join(' ')} #{previous.join(' ')}") unless splits.length > 0
          # our start might be within the previous' in which case its their start, with (greater of our, their ending)
          preferred_end = [e,pe].max
          preferred_type = [t,pt].detect{|t| t == :blank} || :mute # prefer blank to mute
          combined[idx-1] = [ps, preferred_end, preferred_type]
          combined[idx] = nil # allow it to be culled later
        end
        
      end
      previous = current
    }
    combined.compact
  end
  
  def self.translate_string_to_seconds s
    # might actually already be a float, or int, depending on the yaml
    # int for 8 => 9 and also for 1:09 => 1:10
    if s.is_a? Numeric
      return s.to_f
    end
    
    # s is like 1:01:02.0
    total = 0.0
    seconds = nil
    begin
      seconds = s.split(":")[-1]
    rescue Exception => e
     p 'failed!', s
     raise e
    end
    total += seconds.to_f
    minutes = s.split(":")[-2] || "0"
    total += 60 * minutes.to_i
    hours = s.split(":")[-3] || "0"
    total += 60* 60 * hours.to_i
    total
  end
  
  def self.translate_time_to_human_readable seconds, force_hour_stamp = false
    # 3600 => "1:00:00"
    out = ''
    hours = seconds.to_i / 3600
    if hours > 0 || force_hour_stamp
      out << "%d" % hours
      out << ":"
    end
    seconds = seconds - hours*3600
    minutes = seconds.to_i / 60
    out << "%02d" % minutes
    seconds = seconds - minutes * 60
    out << ":"
    
    # avoid an ugly .0 at the end
    if seconds == seconds.to_i
      out << "%02d" % seconds
    else
      out << "%06.3f" % seconds # man that is tricky...
    end
  end
  
  def self.all_edl_files_parsed use_all_not_just_dvds
    dir = EDL_DIR
    dir += "/.." if use_all_not_just_dvds
    Dir[dir + '/**/*.txt'].map{|filename|
        begin
          parsed = parse_file(filename)
          [filename, parsed]
        rescue SyntaxError => e
          # ignore poorly formed edit lists for the auto choose phase...
          p 'warning, unable to parse a file:' + filename + " " + e.to_s
          nil
        end
     }.compact
  end
  
  # returns single matching filename
  def self.find_single_edit_list_matching use_all = false
    matching = all_edl_files_parsed(use_all).map{|filename, parsed|
      yield(parsed) ? filename : nil
    }.compact
    if matching.length == 1
      file = matching[0]
      p "selecting the one only matching EDL: #{file}"
      file
    elsif matching.length > 1
      p "found multiple matches for media? #{matching.inspect}"
      nil
    else
      nil
    end
  end
  
  def self.single_edit_list_matches_dvd dvd_id
    return nil unless dvd_id
    find_single_edit_list_matching {|parsed|
      parsed["disk_unique_id"] == dvd_id
    }
  end

  
end

# == 1.8.7 1.9 Symbol compat

class Symbol
  # Standard in ruby 1.9. See official documentation[http://ruby-doc.org/core-1.9/classes/Symbol.html]
  def <=>(with)
    return nil unless with.is_a? Symbol
    to_s <=> with.to_s
  end unless method_defined? :"<=>"
end

if $0 == __FILE__
  p 'syntax: filename'
  require 'rubygems'
  require 'sane'
  p EdlParser.parse_file(*ARGV)
end
