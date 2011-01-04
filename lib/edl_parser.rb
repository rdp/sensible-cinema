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

require_relative 'overlayer'

class EdlParser

  def self.parse_file filename, ignore_settings = false
    parse_string File.read(filename), filename, [], ignore_settings
  end
  
  # better eye-ball these before letting people run them, eh?
  # but I couldn't think of any other way
  def self.parse_string string, filename, ok_categories_array = [], ignore_settings = false
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
    if ignore_settings
      mutes = blanks = []
    end
    raw["mutes"] = convert_to_timestamp_arrays(mutes, ok_categories_array)
    raw["blank_outs"] = convert_to_timestamp_arrays(blanks, ok_categories_array)
    raw
  end
  
  def self.convert_to_timestamp_arrays array, ok_categories_array
    out = []
    while(single_element = extract_entry!(array))
      # assume that it's always start_time, end_time, category, number
      category = single_element[-2]
      category_number = single_element[-1]
      unless ok_categories_array.index([category, category_number])
        out << single_element
      end
    end
    out
  end
  
  TimeStamp = /^\d+:\d\d[\d:\.]*$/
  # starts with a digit, has at least one colon followed by two digits,then some combo of digits and colons and periods...
  
  def self.extract_entry! from_this
    return nil if from_this.length == 0
    # two digits, then whatever else you see, that's not a digit...
    out = from_this.shift(2)
    out.each{|d|
      raise SyntaxError.new('non timestamp? ' + d) unless d =~ TimeStamp
    }
    while(from_this[0] && from_this[0] !~ TimeStamp)
     out << from_this.shift
    end
    out
  end
  
  def self.get_secs k, splits, offset
    original_secs = translate_string_to_seconds(k)+ offset
    # now if splits is 900 and we'are at 909, then we're just 9
    closest_splits = splits.reverse.detect{|t| t < original_secs} || 0
    original_secs - closest_splits
  end
  
  # divides up mutes and blanks so that they don't overlap, preferring blanks over mutes
  # returns it like [[start,end,type], [s,e,t]...] type like :blank and :mute
  def self.convert_incoming_to_split_sectors incoming, add_this_to_mutes_end = 0, add_this_to_mutes_beginning = 0, splits = []
    if splits != []
      # allow it to do all the double checks we later skip, just in case :)
      self.convert_incoming_to_split_sectors incoming
    end
    mutes = incoming["mutes"] || {}
    blanks = incoming["blank_outs"] || {}
    mutes = mutes.map{|k, v| [get_secs(k, splits, -add_this_to_mutes_beginning), get_secs(v, splits, add_this_to_mutes_end), :mute]}
    blanks = blanks.map{|k, v| [get_secs(k, splits, -add_this_to_mutes_beginning), get_secs(v, splits, add_this_to_mutes_end), :blank]}

    combined = (mutes+blanks).sort
    
    previous = nil
    combined.each_with_index{|current, idx|
      s,e,t = current
      if previous
        ps, pe, pt = previous
        if (s < pe) || (s < ps)
          raise SyntaxError.new("detected an overlap #{[s,e,t].join(' ')} #{previous.join(' ')}") unless splits.length > 0
        end
      end
      if e < s
       raise SyntaxError.new("detected an end before a start: #{e} < #{s}") if e < s unless splits.length > 0
      end
      previous = current
    }

    combined
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

  
end

# <= 1.8.7 Symbol compat

class Symbol
  # Standard in ruby 1.9. See official documentation[http://ruby-doc.org/core-1.9/classes/Symbol.html]
  def <=>(with)
    return nil unless with.is_a? Symbol
    to_s <=> with.to_s
  end unless method_defined? :"<=>"
end