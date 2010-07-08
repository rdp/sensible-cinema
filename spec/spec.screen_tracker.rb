require 'sane'
require_relative 'common'
require_relative '../lib/screen_tracker'

describe ScreenTracker do
  
  before do
    @a = ScreenTracker.new("VLC",10,10,20,20)
  end
  
  it "should be able to grab a picture from screen coords...probably from the current active window" do
    @a.get_bmp.should_not be_nil 
  end
  
  it "should raise if unable to find" do
    proc { ScreenTracker.new("unknown window",10,10,20,20) }.should raise_exception(RuntimeError)
  end
  
  it "should be fast" do
    Benchmark.realtime { @a.get_bmp }.should be < 0.3
  end
  
  context "negative numbers should result in an offset always, and work"
  
  it "should parse yaml appropro"    
  
  after(:all) do
    # bring ourselves back to the foreground
    # lodo why does this BSoD me?
    Win32::Screenshot.window(/universal/, 0) rescue nil
  end
    
end