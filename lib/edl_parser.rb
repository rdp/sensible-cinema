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
  
  # divides up mutes and blanks so that they don't overlap, preferring blanks over mutes
  # returns it like [[start,end,type], [s,e,t]...] type like :blank and :mute
  def self.convert_incoming_to_split_sectors incoming, add_this_to_mutes_end = 0, add_this_to_mutes_beginning = 0
    mutes = incoming["mutes"] || {}
    blanks = incoming["blank_outs"] || {}
    mutes = mutes.map{|k, v| [OverLayer.translate_string_to_seconds(k) - add_this_to_mutes_beginning, OverLayer.translate_string_to_seconds(v) + add_this_to_mutes_end, :mute]}
    blanks = blanks.map{|k, v| [OverLayer.translate_string_to_seconds(k), OverLayer.translate_string_to_seconds(v), :blank]}

    combined = (mutes+blanks).sort_by{|entry| entry[0,1]}
    combined = (mutes+blanks).sort

    combined.each{|s, e, t|
      puts 'warning--detected an end before a start' if e < s
    }

    # VLCProgrammer.convert_to_full_xspf({ "mutes" => {5=> 7}, "blank_outs" => {6=>7} } )
    # should mute 5-6, skip 6-7
    previous = combined[0]
    combined.each_with_index{|(start, endy, type), index|
      next if index == 0 # nothing to do there..
      previous_end = previous[1]
      previous_type = previous[2]
      previous_start = previous[0]
      if type == :blank
        raise 'no overlap like that allowed as of yet' unless previous_end <= endy
        if previous_type == :mute && previous_end > start
          previous[1] = start # make it end when we start...
        end
      elsif type == :mute
        if previous_end > start
          
          if previous_end >= endy
            combined[index] = [nil] # null it out...it's a mute subsumed by a blank apparently...
            if previous_type == :mute
               raise 'overlapping mute?'
            end
            next
          else
             # start mine when the last one ended...
             combined[index] = [previous_end, endy, type]
          end

        end
      else
        raise 'unexpected'
      end
      previous = combined[index] 
    }
    
    combined.select{|start, endy, type|
     (start != nil) && (endy > start) # ignore mutes wholly contained within blanks...
    }
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