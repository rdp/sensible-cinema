require 'faster_rubygems'
require 'sane'
require_relative 'common'
require_relative '../lib/screen_tracker'

describe ScreenTracker do
  
  before(:all) do
    begin
      Win32::Screenshot.window(/VLC/, 0) {}
    rescue
      @pid = IO.popen("C:/program files/VideoLan/VLC/vlc.exe").pid
      sleep 1
    end
  end
  
  before do
    @a = ScreenTracker.new("VLC",10,10,20,20)
  end
  
  it "should be able to grab a picture from screen coords...probably from the current active window" do
    @a.get_bmp.should_not be_nil 
  end
  
  it "should raise if unable to find" do
    proc { ScreenTracker.new("unknown window",10,10,20,20) }.should raise_exception(RuntimeError)
  end
  
  it "should be at least somewhat fast" do
    Benchmark.realtime { @a.get_bmp }.should be < 0.3
  end
  
  it "should not allow for negative widths" do
    proc {ScreenTracker.new("VLC",10,10,-20,20)}.should raise_exception
  end
  
  it "should disallow size 0 widths" do
    proc {ScreenTracker.new("VLC",10,10,0,0)}.should raise_exception
  end
  
  it "should have different bmp if sizes different" do
    a = ScreenTracker.new("VLC",10,10,5,5)
    assert a.get_relative_coords == [10,10,15,15]
    b = ScreenTracker.new("VLC",10,10,50,50)
    assert a.get_bmp != b.get_bmp
  end  
  
  context "negative numbers should result in an offset" do

    it "should allow for negative sizes" do
      a = ScreenTracker.new("VLC",-10,10,5,5)
      a.get_bmp
      a = ScreenTracker.new("VLC",-10,-10,10,10) # right to the edge
      a.get_bmp
      a = ScreenTracker.new("VLC",10,-10,5,5)
      a.get_bmp
    end
    
    it "should assign right coords" do
      a = ScreenTracker.new("VLC",-10,-10,5,5)
      a.get_bmp
      x,y,x2,y2=a.get_relative_coords
      hwnd = Win32::Screenshot::BitmapMaker.hwnd("VLC") 
      always_zero, always_zero, max_x, max_y = Win32::Screenshot::BitmapMaker.dimensions_for(hwnd)      
      x.should == max_x-10
      y.should == max_y-10
      x2.should == x+5
      y2.should == y+5
    end
    
    it "should look different with negative than with positive" do
      a = ScreenTracker.new("VLC",10,10,2,2)
      b = ScreenTracker.new("VLC",10,10,2,2)
      c = ScreenTracker.new("VLC",-100,-100,50,50)
      require 'sane'
      assert a.get_bmp == b.get_bmp
      assert c.get_relative_coords != b.get_relative_coords
      File.binwrite 'c.bmp', c.get_bmp
      File.binwrite 'b.bmp', b.get_bmp
      assert c.get_bmp != b.get_bmp
    end
    
    it "should fail with out of bounds sizes" do
      proc { ScreenTracker.new("VLC",-10,-10,20,20).get_bmp }.should raise_exception
    end
    
  end
  
  it "should parse yaml appropro"    
  
  after(:all) do
    # bring ourselves back to the foreground
    # this seg faults on windows 7 for me for some reason
    unless Socket.gethostname == "PACKRD-1GK7V"
      Win32::Screenshot.window(/universal/, 0) rescue nil
    end
    
  end
  
end