require 'rubygems'
require 'spec/autorun'
require 'sane'
require_relative '../lib/overlayer'
require 'benchmark'
Thread.abort_on_exception = true

describe OverLayer do
  
  before do
    @o = OverLayer.new( {:mutes => {2.0 => 4.0}} )
  end
  
  after do
    # join all...
    Thread.list.each{|t| t.join unless t == Thread.current}
  end
  
  # play a wav file
  # blocking!
  def play file
    system("sndrec32 /play /close #{file}.wav") # lodo this fails at times?
  end
  
  def start_good
    assert !@o.am_muted?
    play("good")
  end
  
  def start_bad
    assert @o.am_muted? # note this uses @o!
    play("bad")
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
    before do
      @yaml = {:mutes => {2.0 => 4.0}}
    end
    
    it 'should mute based on time' do   
      @o.start_thread
      # make sure we enter the mute section
      sleep 2.25
      start_bad
      sleep 1
      start_good
    end
    
    it 'should be able to mute teeny sequences' do
      yaml = {:mutes => {0.0001 => 0.0002, 1.0 => 1.0001}}
      o = OverLayer.new yaml
      o.continue_until_past_all_mutes
    end
  end
  
  context 'startup' do
    it 'should allow you to hit keys and change the current time' do
      @o.start_thread
      sleep 0.1 # wow ruby is slow...
      assert @o.cur_time > 0
      #o.set_time 5
      #assert o.cur_time > 5
    end
    
    it 'should use the times to mute'
    it 'should be able to land directly in or out of one'
    it 'should be able to "key" out of a muted section and it work...'
  end

  it 'should allow for real yaml files somehow'
  
end