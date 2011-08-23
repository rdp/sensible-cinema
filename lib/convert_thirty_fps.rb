module ConvertThirtyFps
  
  def self.from_thirty seconds_float
    twentyNinePointNineSeven = 30000/1001.0 # 29.97
    seconds_float * 30/twentyNinePointNineSeven
  end
  
  def self.from_twenty_nine_nine_seven seconds_float
    twentyNinePointNineSeven = 30000/1001.0
    seconds_float * twentyNinePointNineSeven/30
  end
  
end

if $0 == __FILE__
  p 'syntax: second to convert '
  seconds = eval(ARGV[0] || "1000").to_f
  p 'converted value from 30 to 29.97 is', ConvertThirtyFps.from_thirty(seconds) # should be bigger...
  p 'converted value from 29.97 to 30 is', ConvertThirtyFps.from_twenty_nine_nine_seven(seconds)
end