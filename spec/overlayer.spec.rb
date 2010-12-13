=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
=end
# avoid full loading if testing impossible
if RUBY_VERSION < '1.9.2' && RUBY_PLATFORM !~ /java/
  puts 'not compatible to MRI < 1.9.2'
  exit 0 # this isn't a really real failure...
end

require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/overlayer'

$AM_IN_UNIT_TEST = true

def start_good_blank
  assert !@o.blank?
end

def start_bad_blank
  assert @o.blank?
end

describe OverLayer do

  before do
    File.write 'temp.yml', YAML.dump({:mutes => {2.0 => 4.0}} )
    @o = OverLayer.new('temp.yml')
    Blanker.startup
  end

  after do
    Thread.join_all_others
    File.delete 'temp.yml'
    Blanker.shutdown
  end

  def start_good
    assert !@o.muted?
    sleep 1
  end

  def start_bad
    assert @o.muted? # note this uses @o!
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
    # make sure we enter the mute section, 2-4
    sleep 2.5
    start_bad # sleeps 1
    sleep 1.0
    start_good
  end
  
  it 'should unmute after the ending scene, and also be able to go past the end of scenes at all' do
    File.write 'temp.yml', YAML.dump({:mutes => {0.5 => 1.0}})
    @o = OverLayer.new 'temp.yml'
    @o.start_thread true
    begin
      # make sure we enter the mute section
      sleep 0.75
      start_bad # sleeps 1
      start_good
      start_good
    ensure
      @o.kill_thread!
    end
  end

  it 'should handle multiple mutes in a row' do
    File.write 'temp.yml', YAML.dump({:mutes => {2.0 => 4.0, 5.0 => 7.0}})
    @o = OverLayer.new 'temp.yml'
    @o.start_thread
    sleep 2.5
    start_bad # 1s
    sleep 2 # => 5.5
    start_bad    # unfortunately this doesn't actually reproduce the bug,
    # which is that it actually needs to barely "over sleep" or there is the race condition of
    # wake up oh nothing to do *just* yet
    # but by the time you check again, you just passed it, so you wait till the next one in an errant state
  end

  it 'should be able to mute teeny timed sequences' do
    # it once failed on this...
    File.write 'temp.yml', YAML.dump({:mutes => {0.0001 => 0.0002, 1.0 => 1.0001}})
    o = OverLayer.new 'temp.yml'
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

  it 'should be able to accept keyboard input do adjust time' do
    @o = OverLayer.new 'test_yaml.yml'
    @o.cur_time
    @o.keyboard_input 'm'
    assert @o.cur_time > 59
    @o.keyboard_input 'M'
    assert @o.cur_time < 59
    60.times {
      @o.keyboard_input 's'
    }
    assert @o.cur_time > 59
    60.times {
      @o.keyboard_input 'S'
    }
    assert @o.cur_time < 59
    600.times {
      @o.keyboard_input 't'
    }
    assert @o.cur_time > 59
    600.times {
      @o.keyboard_input 'T'
    }
    assert @o.cur_time < 59

  end

  it 'should have key list output on screen' do
    @o.status.should include("ctrl+c to quit")
  end

  it 'should allow for yaml input and parse it appropo' do
    # 2 - 3 , 4-5 should be muted
    @o = OverLayer.new 'test_yaml.yml'
    @o.start_thread
    start_good # takes 1s
    sleep 1.25
    start_bad
    start_good
    start_bad
    start_good
  end

  def write_yaml yaml
   File.write 'temp.yml', yaml
   @o = OverLayer.new 'temp.yml'
  end

  it 'should allow for 1:00.0 minute style input' do
    write_yaml <<-YAML
    mutes:
      "0:02.0" : "0:03.0"
    YAML
    @o.start_thread
    start_good
    start_good
    sleep 0.25
    start_bad
    start_good
  end

  it "should reload the YAML file on the fly to allow for editing it" do
    # start it with one set to mute far later
    write_yaml <<-YAML
    mutes: 
      "0:11.0" : "0:12.0"
    YAML
    @o.start_thread
    start_good
    File.write 'temp.yml',  <<-YAML
    mutes:
      "0:00.0001" : "0:01.5"
    YAML
    @o.status # cause it to refresh from the file
    sleep 0.1 # blugh avoid race condition since we use notify...
    start_bad
    start_good
  end
  
  it "should not accept any of the input when you pass it any poor yaml" do
    write_yaml <<-YAML
    mutes:
       a : 08:56.0 # first one there is invalid
    YAML
    out = OverLayer.new 'temp.yml'
    out.all_sequences[:mutes].should be_blank    
    write_yaml <<-YAML
    mutes:
       01 : 02
    YAML
    out.reload_yaml!
    out.all_sequences[:mutes].should == [[1,2]]
    write_yaml <<-YAML
    mutes:
       05 : # failure
    YAML
    # should have kept the old
    out.all_sequences[:mutes].should == [[1,2]]
  end
  
  it "should not accept any zero start input" do
    yaml = <<-YAML
    mutes:
       0 : 1 # we don't like zeroes...for now at least, as they can mean parsing failure...
       3 : 4
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == [[3,4]]
  end
  
  it "should disallow zero or less length intervals" do
    yaml = <<-YAML
    mutes:
       1 : 1
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == []  
  end

  
  it "should sort yaml input" do
    yaml = <<-YAML
    mutes:
      3 : 4
      1 : 2
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == [[1,2], [3,4]]
  end
  
  it "should handle non quoted style numbers in yaml" do
    yaml = <<-YAML
    mutes:
       08:55 : 08:56.0 # valid, will return large Fixnum's
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == [[535, 536]]
    yaml = <<-YAML
    mutes:
       01:08:55 : 01:09:55 # actually valid
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == [[4135, 4195]]
  end

  it "should translate yaml with the two different types in it" do
    yaml = <<-YAML
    mutes:
       "0:02.0" : "0:03.0"
    blank_outs:
       "0:02.0" : "0:03.0"  
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == [[2.0, 3.0]]
    out[:blank_outs].should == [[2.0, 3.0]]
    yaml = <<-YAML
    mutes:
       "1:02.11" : "1:03.0"
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].first.should == [62.11, 63.0]
  end

  it "should accept fixnum 56 => 57 style input" do
    yaml = <<-YAML
    mutes:
      "0:02" : "0:03"
      3 : 4
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == [[2.0, 3.0], [3, 4]]
  end
  
  it "should accept numbers that are unreasonably large" do
    yaml = <<-YAML
    mutes:
      1000000 : 1000001
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == [[1_000_000, 1_000_001]]
  end
  
  it "should accept blank yaml" do
    out = OverLayer.translate_yaml ""
    out[:mutes].should be_blank
  end  
  
  it "should not translate symbols"
  
  it "should translate strings as well as symbols" do
    yaml = <<-YAML
    mutes:
      "1" : "3"
    YAML
    out = OverLayer.translate_yaml yaml
    out[:mutes].should == [[1, 3]]
  end  

  it 'should reject overlapping settings...maybe?'
  
  it "should allow for 1:01:00.0 (double colon) style yaml input" do
    write_yaml <<-YAML
    mutes:
      "1:00.11" : "1:03.0"
    YAML
    @o.start_thread
    start_good
    @o.set_seconds 61
    sleep 0.1 # ruby rox again!
    start_bad
    sleep 2
    start_good
  end

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
        @o = OverLayer.new_raw({type => {2.0 => 4.0}})
        @o.discover_state(type, 3).should == [2.0, 4.0, true]
        @o.discover_state(type, 0.5).should == [2.0, 4.0, false]
        @o.discover_state(type, 5).should == [nil, nil, :done]
        @o.discover_state(type, 2.0).should == [2.0, 4.0, true]
        @o.discover_state(type, 4.0).should == [nil, nil, :done]
      end
    end

    context "with a list of blanks" do

      it "should allow for blanks" do
        @o = OverLayer.new_raw({:blank_outs => {2.0 => 4.0}})
        @o.start_thread
        start_good_blank
        sleep 1
        start_good_blank
        sleep 1.1
        start_bad_blank
        sleep 2
        start_good_blank
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
        @o = OverLayer.new_raw({:mutes => {2.0 => 3.5}, :blank_outs => {3.0 => 4.0}})
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
        
        @o = OverLayer.new_raw({:mutes => {2.0 => 3.5, 5 => 6}, :blank_outs => {3.0 => 4.0}})
        
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

    it "should have human readable output" do
      @o.translate_time_to_human_readable(3600).should == "1:00:00.0"
      @o.translate_time_to_human_readable(3600.0).should == "1:00:00.0"
      @o.translate_time_to_human_readable(3601).should == "1:00:01.0"
      @o.translate_time_to_human_readable(3661).should == "1:01:01.0"
    end

    it "should no longer accept human readable style as starting seconds" do
      proc { OverLayer.new 'temp.yml', "01:01.5" }.should raise_error(ArgumentError)
    end

  end

end