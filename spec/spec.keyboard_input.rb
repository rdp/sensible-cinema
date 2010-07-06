require File.dirname(__FILE__) + '/common'
require_relative '/../lib/keyboard_input'

describe KeyboardInput do

  class Go
    @time = 58
    def self.cur_time
      @time += 1
    end
  end

  
  it "should display some seconds" do

    a = KeyboardInput.new Go
    a.get_line_printout.should include("0:59")
    a.get_line_printout.should include("1:00")
    
  end
  
  
end
