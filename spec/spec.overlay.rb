require File.dirname(__FILE__) + '/common'
require_relative '../lib/overlayer'
require 'yaml'
$TEST = true
describe OverLayer do
  
  before do
    @o = OverLayer.new( {:mutes => {2.0 => 4.0}} )
  end
  
  after do
    Thread.join_all_others
  end
  
  def start_good
    pps 'doing start_good', Time.now_f if $VERBOSE
    assert !@o.am_muted?
    sleep 1
  end
  
  def start_bad
    pps 'doing start_bad', Time.now_f if $VERBOSE
    assert @o.am_muted? # note this uses @o!
    sleep 1
  end
  
  it 'should be able to mute' do
    # you shouldn't hear a beep
    assert !@o.am_muted?
    @o.mute!
    assert @o.am_muted?
    @o.unmute!
    assert !@o.am_muted?
    @o.mute!
    assert @o.am_muted?
  end
  
  context 'given you know when to start' do
    
    it 'should mute based on time' do   
      @o.start_thread
      # make sure we enter the mute section
      sleep 2.25
      start_bad
      sleep 1
      start_good
    end
    
    it 'should handle multiple mutes in a row' do
      settings = {:mutes => {2.0 => 4.0, 5.0 => 7.0}}
      @o = OverLayer.new settings
      @o.start_thread
      sleep 2.5
      start_bad # 1s
      sleep 2 # => 5.5
      start_bad
    end
    
    it 'should be able to mute teeny sequences' do
      settings = {:mutes => {0.0001 => 0.0002, 1.0 => 1.0001}}
      o = OverLayer.new settings
      o.continue_until_past_all_mutes false
    end
  end
  
  context 'startup' do
    it 'should allow you to change the current time' do
      @o.start_thread
      sleep 0.1 # wow ruby is slow...
      assert @o.cur_time > 0
      @o.set_seconds 5
      sleep 0.1
      assert @o.cur_time > 5
    end
    
    it 'should be able to land directly in or out of one'
    
    it 'should be able to hit keys to affect input' do
      @o.cur_time
      @o.keyboard_input 'M'
      assert @o.cur_time > 59 
      @o.keyboard_input 'm'
      assert @o.cur_time < 59
      60.times {
        @o.keyboard_input 'S'
      }
      assert @o.cur_time > 59 
      60.times {
        @o.keyboard_input 's'
      }
      assert @o.cur_time < 59 
      600.times { 
        @o.keyboard_input 'T' 
      }
      assert @o.cur_time > 59 
      600.times { 
        @o.keyboard_input 't' 
      }
      assert @o.cur_time < 59 
    
    end
    
    it 'should be able to "key" into and out of a muted section and it work...'

  end

  it 'should have help output' do
    @o.status.should include "MmSs"
  end  

  it 'should allow for real yaml files somehow and use it' do
    yaml = File.read("test_yaml.yml")
    # 2 - 3 , 4-5 should be muted
    @o = OverLayer.new_yaml yaml
    @o.start_thread
    start_good # takes 1s
    sleep 1.25
    start_bad
    start_good
    start_bad
    start_good
  end
  
  it 'should allow for 1:00.0 minute style input' do
    yaml = <<YAML
:mutes:
  "0:02.0" : "0:03.0"
YAML
    @o = OverLayer.new_yaml yaml
    @o.start_thread
    start_good
    start_good
    sleep 0.25
    start_bad
    start_good
  end

  it "should translate yaml well" do
    yaml = <<YAML
:mutes:
  "0:02.0" : "0:03.0"
YAML
#require '_dbg'
     out = OverLayer.translate_yaml yaml
     out[:mutes].first.should == [2.0, 3.0]
     yaml = <<YAML
:mutes:
  "1:02.11" : "1:03.0"
YAML
     out = OverLayer.translate_yaml yaml
     out[:mutes].first.should == [62.11, 63.0]
  end

  it "should disallow negative lengths"

  it "should allow for 1:01:00.0 (double colon) style input"

  it 'should give you lightning accurate timestamps when you hit space, in 1:00.0 style'
  
  it 'should be able to continue *past* the very end, then back into it, etc.'
  
  it 'should have a user friendlier yaml syntax'

  it 'should have a more descriptive yaml syntax'

end