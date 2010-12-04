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
    blanks = raw["blanks"] || []
    require 'ruby-debug'
#    debugger
    raw
  end
  
  Timestamp = /[\d:\.]+/
  
  def self.extract_entry! from_this
    # two digits, then whatever else you want, that's not a digit
    out = from_this.shift(2)
    while(from_this[0] && from_this[0] !~ Timestamp)
     out << from_this.shift
    end
    out    
  end

end