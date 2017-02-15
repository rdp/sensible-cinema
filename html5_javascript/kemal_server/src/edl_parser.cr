class EdlParser
  
  # this one is 1:01:02.0 => 36692.0
  # its reverse is this: translate_time_to_human_readable
  def self.translate_string_to_seconds(s)
    # might actually already be a float, or int, depending on the yaml
    # int for 8 => 9 and also for 1:09 => 1:10
    if s.is_a? Number
      return s.to_f # easy out.
    end
    
    s = s.strip
    # s is like 1:01:02.0
    total = 0.0
    seconds = nil
    seconds = s.split(":")[-1]
    raise "does not look like a timestamp? " + seconds.inspect unless seconds =~ /^\d+(|[,.]\d+)$/
    seconds = seconds.gsub("," , ".")
    total += seconds.to_f
    minutes = s.split(":")[-2] || "0"
    total += 60 * minutes.to_i
    hours = s.split(":")[-3] || "0"
    total += 60* 60 * hours.to_i
    total
  end

  
  # TimeStamp = /(^\d+:\d\d[\d:\.]*$|\d+)/ # this one also allows for 4444 [?] and also weirdness like "don't kill the nice butterfly 2!" ...
  TimeStamp = /^\s*(\d+:\d\d[\d:\.]*|\d+\.\d+)\s*$/ # allow 00:00:00 00:00:00.0 1222.4 " 2:04 "
  # disallow's 1905 too but elsewhere in the code
  
  def self.extract_entry!(from_this)
    return nil if from_this.length == 0
    # two digits, then whatever else you see, that's not a digit...
    out = from_this.shift(2)
    out.each{|d|
      unless d =~ TimeStamp
        raise SyntaxError.new("non timestamp? " + d.inspect) 
      end
    }
    while(from_this[0] && from_this[0] !~ TimeStamp)
      raise SyntaxError.new("straight non fractional digits not allowed use 1000.0 instead") if from_this[0] =~ /^\d+$/
      out = out +  from_this.shift
    end
    out
  end
  
end

if $0 == __FILE__
  p "syntax: filename"
  #parsed = EdlParser.parse_file(ARGV[0]) # this was the old and parsing...uh...edl's not srt's
  # p "parsed well"
  # print parsed.inspect
end
