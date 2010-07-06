require File.dirname(__FILE__) + '/common'
require_relative '../lib/overlayer'
require 'yaml'

describe OverLayer do
  
  before do
    @o = OverLayer.new( {:mutes => {2.0 => 4.0}} )
  end
  
  after do
    # join all...
    Thread.list.each{|t| t.join unless t == Thread.current}
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
      yaml = {:mutes => {2.0 => 4.0, 5.0 => 7.0}}
      @o = OverLayer.new yaml
      @o.start_thread
      sleep 2.5
      start_bad # 1s
      sleep 2 # => 5.5
      start_bad
    end
    
    it 'should be able to mute teeny sequences' do
      yaml = {:mutes => {0.0001 => 0.0002, 1.0 => 1.0001}}
      o = OverLayer.new yaml
      o.continue_until_past_all_mutes
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
    
    it 'should not let you go below zero'
    
    it 'should be able to "key" into and out of a muted section and it work...'

  end

  it 'should allow for real yaml files somehow and use it' do
    settings = YAML.load File.read("test_yaml.yml")
    # 2 - 3 , 4-5 should be muted
    @o = OverLayer.new settings
    @o.start_thread
    start_good # takes 1s
    sleep 1.25
    start_bad
    start_good
    start_bad
    start_good
  end
  
  # lodo: it continue forever when run from bin...never exit the watcher thread...I guess...
  
end