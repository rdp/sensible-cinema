require 'sane'
require_relative 'common'
require_relative '../lib/screen_tracker'

describe ScreenTracker do
  
  it "should be able to grab a picture from screen coords...probably from the current active window" do
    a = ScreenTracker.new("VLC",10,10,20,20)
    a.get_bmp.should_not be_nil    
  end
  
  context "negative numbers should result in an offset always, and work" do
  
  end
  
  it "should parse yaml appropro"
    
    
end