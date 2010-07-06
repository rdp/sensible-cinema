require 'rubygems'
require 'spec/autorun'
require 'sane'
require_relative '../lib/overlayer'
require 'benchmark'
Thread.abort_on_exception = true

describe OverLayer do
  
  before do
    OverLayer.unmute!
  end
  
  after do
    Thread.list.each{|t| t.join unless t == Thread.current}
  end
  
  # play a wav file
  # blocking!
  def play file
    system("sndrec32 /play /close #{file}.wav") # lodo this fails at times?
  end
  
  def start_good
    assert !OverLayer.am_muted?
    play("good")
  end
  
  def start_bad
    assert OverLayer.am_muted?
    play("bad")
  end
  
  it 'should be able to mute' do
    # you shouldn't hear a beep
    assert !OverLayer.am_muted?
    OverLayer.mute!
    assert OverLayer.am_muted?
    OverLayer.unmute!
    assert !OverLayer.am_muted?
    OverLayer.mute!
    assert OverLayer.am_muted?
  end
  
  context 'given you know when to start' do
    
    it 'should mute based on time' do
      yaml = {:mutes => {2.0 => 4.0}}
      Thread.new { OverLayer.overlay yaml}
      # make sure we enter the mute section
      sleep 2.25
      start_bad
      sleep 1
      start_good
    end
    
    it 'should be able to mute teeny sequences ' do
      yaml = {:mutes => {0.0001 => 0.0002, 1.0 => 1.0001}}
      OverLayer.overlay yaml
    end
  end
  
  context 'startup' do
    it 'should allow you to hit keys and change the setup'
    it 'should use the times to mute'
    it 'should be able to land directly in or out of one'
  end

  it 'should allow for real yaml files somehow'
  
end