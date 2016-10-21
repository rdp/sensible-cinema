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

$AM_IN_UNIT_TEST = true

def assert_not_blank
  assert !@o.blank?
end

def assert_blank
  assert @o.blank?
end

def new_raw ruby_hash
  File.write 'temp.json', JSON.dump(ruby_hash)
  OverLayer.new('temp.json')
end

describe OverLayer do

  before do
    File.write 'temp.json', JSON.dump({:mutes => {2.0 => 4.0}} )
    @o = OverLayer.new('temp.json')
    Blanker.warmup
  end

  after do
    # sometimes blocks on some cruppy UI threds
    # Thread.join_all_others
    File.delete 'temp.json'
    Blanker.shutdown
  end

  def assert_not_muted_sleep_1
    assert !@o.muted?
    sleep 1
  end

  def assert_muted_sleep_1
    assert @o.muted?
    sleep 1
  end

  it 'should be able to mute' do
    # several combinations...
    assert !@o.muted?
    @o.mute!
    assert @o.muted?
    @o.unmute!
    assert !@o.muted?
    @o.mute!
    assert @o.muted?
  end

  it 'should mute based on time' do
    @o.start_thread
    assert !@o.muted?
    # make sure we enter the mute section, 2-4
    sleep 2.5
    assert_muted_sleep_1 # sleeps 1
    sleep 1.0
    assert_not_muted_sleep_1
  end
  
  it 'should unmute after the ending scene, and also be able to go past the end of scenes at all' do
    File.write 'temp.json', JSON.dump({:mutes => {0.5 => 1.0}})
    @o = OverLayer.new 'temp.json'
    @o.start_thread true
    begin
      # make sure we enter the mute section
      sleep 0.75
      assert_muted_sleep_1 # sleeps 1
      assert_not_muted_sleep_1
      assert_not_muted_sleep_1
    ensure
      @o.kill_thread!
    end
  end

  it 'should handle multiple mutes in a row' do
    File.write 'temp.json', JSON.dump({:mutes => {2.0 => 4.0, 5.0 => 7.0}})
    @o = OverLayer.new 'temp.json'
    @o.start_thread
    sleep 2.5
    assert_muted_sleep_1 # 1s
    sleep 2 # => 5.5
    assert_muted_sleep_1    # unfortunately this doesn't actually reproduce the bug,
    # which is that it actually needs to barely "over sleep" or there is the race condition of
    # wake up oh nothing to do *just* yet
    # but by the time you check again, you just passed it, so you wait till the next one in an errant state
  end

  it 'should be able to mute teeny timed sequences' do
    # it once failed on this...
    File.write 'temp.json', JSON.dump({:mutes => {0.0001 => 0.0002, 1.0 => 1.0001}})
    o = OverLayer.new 'temp.json'
    o.continue_until_past_all false
  end


  it 'should allow you to change the current time' do
    @o.start_thread
    sleep 0.1 # wow ruby is slow...
    assert @o.cur_time > 0
    @o.set_seconds 5
    sleep 0.1
    assert @o.cur_time > 5
  end

  it 'should allow for json input and parse it appropo' do
    # 2 - 3 , 4-5 should be muted
    @o = OverLayer.new 'test_json.json'
    @o.start_thread
    assert_not_muted_sleep_1 # takes 1s
    sleep 1.25
    assert_muted_sleep_1
    assert_not_muted_sleep_1
    assert_muted_sleep_1
    assert_not_muted_sleep_1
  end

  def write_json json
   File.write 'temp.json', json
   @o = OverLayer.new 'temp.json'
  end

  def dump_json to_dump
    File.write 'temp.json', JSON.dump(to_dump)
    @o = OverLayer.new 'temp.json'
  end

  def write_json_single_mute(start, endy)
    write_json "{\"mutes\":[[\"#{start}\",\"#{endy}\"]],\"skips\":[]}"
  end

  it 'should allow for 1:00.0 minute style input' do
    write_json_single_mute("0:02.0", "0:03.0")
    @o.start_thread
    assert_not_muted_sleep_1
    assert_not_muted_sleep_1
    sleep 0.25
    assert_muted_sleep_1
    assert_not_muted_sleep_1
  end

  it "should reload the JSON file on the fly to allow for editing it" do
    # start it with one set to mute far later
    write_json_single_mute("0:11.0", "0:12.0")
    @o.start_thread
    assert_not_muted_sleep_1
    write_json_single_mute("0:00.0001", "0:01.5")
    @o.status # cause it to refresh from the file
    sleep 0.1 # blugh avoid race condition since we use notify, let the message be received...
    puts 'current state', @o.get_current_state
    assert_muted_sleep_1
    sleep 1
    assert_not_muted_sleep_1
  end
  
  it "should not accept any of the input when you pass it any poor json" do
    write_json_single_mute("a", "08:56.0") # first one there is invalid
    out = OverLayer.new 'temp.json' # so I can call reload
    out.all_sequences[:mutes].should be_blank    
    write_json_single_mute("01", "02")
    out.reload_json!
    out.all_sequences[:mutes].should == [[1,2]]
    write_json_single_mute("05", "") # failure on second
    # should have kept the old
    out.all_sequences[:mutes].should == [[1,2]]
  end
  
  it "should not accept any zero start input" do
    dump_json({:mutes => {0=> 1, 2.0 => 4.0}}) # we don't like zeroes...for now at least, as they can mean parsing failure...
    out = OverLayer.parse_from_json_string File.read("temp.json")
    out[:mutes].should == [[3,4]]
  end
  
  it "should disallow zero or less length intervals" do
    write_json_single_mute('1', '1')
    out = OverLayer.parse_from_json_string File.read("temp.json")
    out[:mutes].should == []  
  end
  
  it "should sort json input" do
    dump_json({:mutes => {3=> 4, 1 => 2}})
    out = OverLayer.parse_from_json_string File.red("temp.json")
    out[:mutes].should == [[1,2], [3,4]]
  end
  
  it "should accept numbers that are unreasonably large" do
    write_json_single_mute "1000000", "1000001"
    out = OverLayer.parse_from_json_string File.read("temp.json")
    out[:mutes].should == [[1_000_000, 1_000_001]]
  end
  
  it 'should reject overlapping settings...maybe?' # actually I'm thinking respect as long as they're not the same types...this should be done on the server anyway :|
  
  it "should be able to handle it when the sync message includes a new timestamp" do
    @o.start_thread
    @o.timestamp_changed "1:00:01", 0
    @o.cur_time.should be > 60*60
    @o.timestamp_changed "0:00:01", 0
    @o.cur_time.should be < 60*60
  end

  it "should handle deltas to input timestamps" do
    @o.start_thread
    @o.timestamp_changed "1:00:00", 1
    @o.cur_time.should be >= 60*60 + 1
  end

  context "should handle blanks, too" do
    it "should be able to discover next states well" do
      for type in [:blank_outs, :mutes] do
        @o = new_raw({type => {2.0 => 4.0}})
        @o.discover_state(type, 3).should == [2.0, 4.0, true]
        @o.discover_state(type, 0.5).should == [2.0, 4.0, false]
        @o.discover_state(type, 5).should == [nil, nil, :done]
        @o.discover_state(type, 2.0).should == [2.0, 4.0, true]
        @o.discover_state(type, 4.0).should == [nil, nil, :done]
      end
    end

    context "with a list of blanks" do

      it "should allow for blanks" do
        @o = new_raw({:blank_outs => {2.0 => 4.0}})
        @o.start_thread
        assert_not_blank
        sleep 1
        assert_not_blank
        sleep 1.1
        assert_blank
        sleep 2
        assert_not_blank
      end
    end

    def at time
      @o.stub!(:cur_time) {
        time
      }
      yield
    end

    context "mixed blanks and others" do
      it "should allow for mixed" do
        @o = new_raw({:mutes => {2.0 => 3.5}, :blank_outs => {3.0 => 4.0}})
        at(1.5) do
          @o.cur_time.should == 1.5
          @o.get_current_state.should == [false, false, 2.0]
        end

        at(2.0) do
          @o.get_current_state.should == [true, false, 3.0]
        end

        at(3.0) do
          @o.get_current_state.should == [true, true, 3.5]
        end

        at(4) do
          @o.get_current_state.should == [false, false, :done]
        end
        
        # now a bit more complex...
        
        @o = new_raw({:mutes => {2.0 => 3.5, 5 => 6}, :blank_outs => {3.0 => 4.0}})
        
        at(3.75) do
          @o.get_current_state.should == [false, true, 4.0]
        end
        
        at(5) do
          @o.get_current_state.should == [true, false, 6]
        end
        
        at(6) do
          @o.get_current_state.should == [false, false, :done]
        end

      end
    end

    it "should not fail with verbose on, after it's past next states" do
      at(500_000) do
        @o.status.should include("138:53:20")
        @o.status.should include("q") # for quit
      end
    end
    
    it "should no longer accept human readable style as starting seconds" do
      proc { OverLayer.new 'temp.json', "01:01.5" }.should raise_error(ArgumentError)
    end

  end

end
