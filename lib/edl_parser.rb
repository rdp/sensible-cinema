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