=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end
require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/overlayer'
require_relative '../lib/screen_tracker'

describe ScreenTracker do

  SILENCE = /silence.*VLC/

  def start_vlc
    unless $pid1
      assert !$pid1
      # enforce we only have at most one running...
      begin
        Win32::Screenshot.window(SILENCE, 0) {}
        raise Exception.new('must close existing vlcs first')
      rescue
        silence = File.expand_path("./silence.wav").gsub("/", "\\")
        vlc =  Dir['/program files*/videolan/VLC/vlc.exe'][0]
        Dir.chdir(File.dirname(vlc)) do; IO.popen("vlc.exe #{silence}").pid; end # includes a work around for JRUBY-4959 /4958
        
        # now also work around JRUBY-5756
        until $pid1
          $pid1 = GetPid.get_process_id_from_window(Win32::Screenshot::Util.window_hwnd(SILENCE)) rescue nil
          sleep 0.01
        end
      end
    end
  end

  before(:all) do
    start_vlc
  end

  before do
    @a = ScreenTracker.new(SILENCE,10,10,20,20)
  end

  it "can take a regex or string" do
    ScreenTracker.new(SILENCE,10,10,20,20)
    ScreenTracker.new("silence",10,10,20,20)
  end

  it "should be able to grab a picture from screen coords...probably from the current active window" do
    @a.get_bmp.should_not be_nil
  end

  it "should loop if unable to find the right window" do
    proc {
      Timeout::timeout(1) do
        ScreenTracker.new("this is supposed to be not running",10,10,20,20)
      end
    }.should raise_error(Timeout::Error)
  end

  it "should be at least somewhat fast" do
    Benchmark.realtime { @a.get_bmp }.should be < 0.3
  end

  it "should not allow for negative widths" do
    proc {ScreenTracker.new("VLC",10,10,-20,20)}.should raise_error
  end

  it "should disallow size 0 widths" do
    proc {ScreenTracker.new("VLC",10,10,0,0)}.should raise_error
  end

  it "should have different bmp if sizes different" do
    a = ScreenTracker.new("VLC",10,10,5,5)
    assert a.get_relative_coords == [10,10,15,15]
    b = ScreenTracker.new("VLC",10,10,50,50)
    assert a.get_bmp != b.get_bmp
  end

  it "should allow for straight desktop if they specify Desktop or desktop" do
    a = ScreenTracker.new("desktop",0,0,100,100)
  end

  context "negative numbers should be interpreted as an offset" do

    it "should allow for negative size parameter" do
      a = ScreenTracker.new("VLC",-10,10,5,5)
      a.get_bmp
      a = ScreenTracker.new("VLC",-10,-10,10,10) # right to the edge
      a.get_bmp
      a = ScreenTracker.new("VLC",10,-10,5,5)
      a.get_bmp
    end

    it "should assign right offsets" do
      a = ScreenTracker.new("VLC",-10,-10,5,5)
      a.get_bmp
      x,y,x2,y2=a.get_relative_coords
      hwnd = Win32::Screenshot::BitmapMaker.hwnd("VLC")
      max_x, max_y = Win32::Screenshot::Util.dimensions_for(hwnd)
      x.should == max_x-10
      y.should == max_y-10
      x2.should == x+5
      y2.should == y+5
    end

    it "should take negative coords and appear to use them" do
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
      proc { a = ScreenTracker.new(SILENCE,-10,10,20,20) }.should raise_error
      proc { a = ScreenTracker.new(SILENCE,10,-10,20,20) }.should raise_error
      proc { a = ScreenTracker.new(SILENCE,-10,10,0,2)   }.should raise_error
      proc { a = ScreenTracker.new(SILENCE,10,10,2,0)    }.should raise_error
    end

  end

  # lodo: this 7 looks rather redundant...
  it "should parse yaml appropro" do
      yaml = <<-YAML
      name: VLC
      x: 32
      y: 34
      width: 100
      height: 20
      digits:
      :hours:
      :minute_tens:
      - -90
      - 7
      :minute_ones:
      - -82
      - 7
      :second_tens:
      - -72
      - 7
      :second_ones:
      - -66
      - 7
    YAML
    a = ScreenTracker.new_from_yaml(yaml,nil)
    a.get_relative_coords.should == [32,34,132,54]
  end

  it "should be able to dump images it uses" do
    @a.dump_bmp
    assert File.exist?('dump.bmp') && File.exist?('all.dump.bmp')
  end

  context "tracking a real player that is moving" do

    before do
      @a = ScreenTracker.new(SILENCE, -111, -16, 86, 13)
    end

    it "should be able to poll the screen to know when something changes" do
      @a.wait_till_next_change
      # it updates every 1 second...
      Benchmark.realtime { @a.wait_till_next_change }.should be > 0.2
      @a.dump_bmp # for debugging...
    end

    it "should be able to track via class_name" do
      a = ScreenTracker.new(SILENCE,10,10,20,20)
      b = ScreenTracker.new(/qwidget/i,10,10,20,20, true, {:second_ones => [-66, 7]})
      a.hwnd.should == b.hwnd
    end

  end

  context "using hulu" do
    it "should be able to parse all digits" do
      pending "completion"
      a = ScreenTracker.new_from_yaml File.read("../zamples/players/hulu/total_length_over_an_hour.txt"), nil
    end
    
  end
  
  context "using youtube" do
    it "should be able to parse"
  end
  
  context "using a digit capable setting" do

    before do
      @a = ScreenTracker.new_from_yaml File.read("../zamples/players/vlc/windowed_total_length_under_an_hour.txt"), nil
    end

    it "should use OCR against the changes appropriately" do
      sleep 1.1 # sleep until it should show something for sure
      output = @a.wait_till_next_change # grab a real change
      output[0].should be_a(String)
      output[0].should include("00:") # like 00:09 or what not...
      output[0].should match(/[1-9]/)
      output[1].should be_a(Float)
    end

    it "should be able to scan for/identify new windows, since VLC creates entirely new windows when it transition
    from menu -> player" do
      
      output = @a.wait_till_next_change
      output[0].should_not be_nil
      old_handle = @a.hwnd
      kill_vlc
      start_vlc
      output = @a.wait_till_next_change
      output[0].should_not be_nil
      old_handle.should_not == @a.hwnd
    end

    it "should be able to disk dump its digit images" do
      @a.dump_bmp
      # what is the right number here?
      Pathname.new('minute_tens.1.bmp').should exist
      Pathname.new('minute_tens.1.bmp').size.should be > 0
      # doesn't have hours
      Pathname.new('hours.1.bmp').should_not exist
    end

    it "should be ok with a non-existent (non-returned) hours image" do
      @a.stub!(:get_digits_as_bitmaps) do
        four = File.binread('images/vlc_4.bmp')
        black = File.binread('images/black.bmp')
        {:minute_tens=>four,:second_tens => four, :second_ones => four, :minute_ones => four,
        :hours => black}
      end
      @a.attempt_to_get_time_from_screen(Time.now)[0].should == "0:44:44" # hour is zero
    end

    it "should track the screen until it stabilizes, as VLC has a slight lag when seconds turn but minutes don't for a tidge" do
      time_through = 0
      four = File.binread('images/vlc_4.bmp')
      black = File.binread('images/black.bmp')
      times_read=0
      @a.stub!(:get_digits_as_bitmaps) do
        time_through += 1
        if time_through == 1
          {:minute_tens=>four}
        elsif time_through == 2
          {:minute_tens=>black}
        else
          # just return the same thing
          times_read += 1
          {:minute_tens=>four,:second_tens => four, :second_ones => four, :minute_ones => four,
          :hours => four}
        end
      end

      got = @a.attempt_to_get_time_from_screen(Time.now)
      time_through.should == 4
      times_read.should == 2
      got[0].should == "4:44:44"
    end

    context "with an OCR that can change from hour to minutes during ads" do
      it "should detect this change and act appropriately"
    end

    it "should be able to pass through the option to invert images" do
      @a = ScreenTracker.new(SILENCE, 100, 100, 10, 10, false,
      {:should_invert => true, :second_ones => [-66, 7]} ) # VLC descriptor is messed currently...
      got_it = nil
      OCR.stub!(:identify_digit) {|*args|
        got_it = args
      }
      @a.identify_digit('some binary bitmap data')
      got_it[1][:should_invert].should be_true
    end
  end
  

  def kill_vlc
    assert $pid1
    # jruby...<sigh>
    system("taskkill /pid #{$pid1}")
    Process.kill 9, $pid1 # MRI...sigh.
    FileUtils.rm_rf Dir['*.bmp']
    $pid1 = nil
    sleep 1
  end

  after(:all) do
    kill_vlc
  end
end
