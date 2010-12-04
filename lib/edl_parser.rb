class EdlParser

  def self.parse_file filename
    parse_string File.read(filename)
  end
  
  # better eye-ball these before letting people run them, eh?
  # but I couldn't think of any other way
  def self.parse_string string
    string = '{' + string + '}'
    raw = eval string
    
    # mutes and blank_outs need to be special parsed into arrays...
    mutes = raw["mutes"] || []
    blanks = raw["blank_outs"] || []
    raw["mutes"] = convert_to_timestamp_arrays(mutes)
    raw["blank_outs"] = convert_to_timestamp_arrays(blanks)
    raw
  end
  
  def self.convert_to_timestamp_arrays array
    out = []
    while(single_element = extract_entry!(array))
      out << single_element
    end
    out
  end
  
  TimeStamp = /^\d+:\d\d[\d:\.]*$/
  # if it has at least one colon, followed by a digit, then a digit, then some combo of digits and colons...
  
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