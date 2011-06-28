module ConvertThirtyFps
  def self.from_thirty seconds_float
    twentyNinePointNineSeven = 30000/1001.0
    seconds_float * 30/twentyNinePointNineSeven
  end
end

if $0 == __FILE__
  p 'syntax: second to convert from 30 to 29.97'
  seconds = eval(ARGV[0] || "1000").to_f
  p 'converted value is', ConvertThirtyFps.from_thirty(seconds) # should get bigger...
end