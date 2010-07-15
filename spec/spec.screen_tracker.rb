require 'faster_rubygems'
require 'sane'
require_relative 'common'
require_relative '../lib/screen_tracker'

describe ScreenTracker do
  
  before(:all) do
    begin
      Win32::Screenshot.window(/silence.wav/, 0) {}
    rescue
      # this way we'll only have one up...
      @pid1 = IO.popen("C:/program files/VideoLan/VLC/vlc.exe silence.wav").pid
      sleep 2
    end
    
  end
  
  before do
    @a = ScreenTracker.new(/silence.*VLC/,10,10,20,20)
  end
  
  it "can take a regex or string" do
    ScreenTracker.new(/silence.*VLC/,10,10,20,20)
    ScreenTracker.new("silence",10,10,20,20)
  end
  it "should be able to grab a picture from screen coords...probably from the current active window" do
    @a.get_bmp.should_not be_nil 
  end
  
  it "should loop if unable to find the right window" do
    proc { 
      Timeout::timeout(1) { ScreenTracker.new("unknown window",10,10,20,20) }
          }.should raise_exception(Timeout::Error)
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
      a = ScreenTracker.new("VLC",10,10,50,50)
      b = ScreenTracker.new("VLC",10,10,50,50)
      c = ScreenTracker.new("VLC",-99,-99,50,50)
      assert a.get_bmp == b.get_bmp
      assert c.get_relative_coords != b.get_relative_coords
      cb = c.get_bmp
      bb = b.get_bmp
      c.get_bmp.length == b.get_bmp.length
      assert c.get_bmp != b.get_bmp
    end
    
    it "should fail with out of bounds or zero sizes" do
      proc { a = ScreenTracker.new(/silence.*VLC/,-10,10,20,20) }.should raise_exception 
      proc { a = ScreenTracker.new(/silence.*VLC/,10,-10,20,20) }.should raise_exception
      proc { a = ScreenTracker.new(/silence.*VLC/,-10,10,0,2) }.should raise_exception
      proc { a = ScreenTracker.new(/silence.*VLC/,10,10,2,0) }.should raise_exception
    end
    
  end
  
  it "should parse yaml appropro" do
    yaml = <<YAML
name: VLC
x: 32
y: 34
width: 100
height: 20
YAML
    a = ScreenTracker.new_from_yaml(yaml,nil)
    a.get_relative_coords.should == [32,34,132,54]
  end

  it "should be able to dump its contents" do
    @a.dump_bmp
    assert File.exist?('dump.bmp') && File.exist?('all.dump.bmp')
  end
  
  context "given a real player that is moving" do
    
    before do
      @a = ScreenTracker.new("silence.wav", -111, -16, 86, 13)  
    end
    
    it "should be able to poll the screen to know when something changes" do
      @a.wait_till_next_change {}
      # it updates every 1 second...
      Benchmark.realtime { @a.wait_till_next_change {} }.should be > 0.2
      @a.dump_bmp # for debugging...
    end
    
    it "should use OCR against the changes appropriately" do
      pending "OCR" do
        output = nil
        @a.wait_till_next_change {|cur_time|    
          output = cur_time
        }
        output.should be_a( Float)
      end
    end
    
  end
  
  it "should have next versions" do
    pending "next versions" do      
      it "should stay on it with the mouse for the first 40 seconds after any drastic change"
      
      it "should be able to OCR all manner of single digits, colons, and non-those" 
      
      it "with VLC should be able to recognize when it goes past an hour somehow...probably by presence of hourly colon"
      
      it "should work with hulu 'every so often polling' full screen"
    end
  end
    
  after(:all) do
    # bring redcar to the foreground
    # this seg faults on windows 7 for me for some reason when run inside the editor itself...swt bug?
    unless Socket.gethostname == "PACKRD-1GK7V"
      Win32::Screenshot.window(/universal/, 0) rescue nil
    end
    Process.kill 9, @pid1 rescue nil # need this re-started each time or the screen won't change for the screen changing test
    FileUtils.rm_rf Dir['*.bmp']
  end
  
end