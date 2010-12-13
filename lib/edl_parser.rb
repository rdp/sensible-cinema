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
class EdlParser

  def self.parse_file filename
    parse_string File.read(filename), filename
  end
  
  # better eye-ball these before letting people run them, eh?
  # but I couldn't think of any other way
  def self.parse_string string, filename, ok_categories_array = []
    string = '{' + string + "\n}"
    if filename
     raw = eval(string, binding, filename)
    else
     raw = eval string
    end
    
    # mutes and blank_outs need to be special parsed into arrays...
    mutes = raw["mutes"] || []
    blanks = raw["blank_outs"] || []
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
      raise 'non timestamp? ' + d unless d =~ TimeStamp
    }
    while(from_this[0] && from_this[0] !~ TimeStamp)
     out << from_this.shift
    end
    out
  end

end