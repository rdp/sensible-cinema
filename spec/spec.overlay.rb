require 'rubygems'
require 'spec/autorun'
require 'sane'
require_relative '../lib/overlayer'

describe OverLayer do
  
  before do
    OverLayer.unmute!
  end
  
  def play file
    system("sndrec32 /play /close #{file}.wav") # this fails at times?
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
    start_bad
    sleep 2
    OverLayer.unmute!
    assert !OverLayer.am_muted?
  end
  
  context 'given you know when to start' do
    
    it 'should mute for 1s' do
      yaml = {:mutes => {2.0 => 4.0}}
      a = Thread.new { OverLayer.overlay yaml, 10 } # 10 seconds
      pps 'start good', Time.now_f
      start_good # sec's 0-3
      pps 'good started:', Time.now_f
      sleep 3
      pps 'start bad, time:', Time.now_f
      #require '_dbg'
      start_bad # sec's 3-6 muted
      sleep 3
      pps 'good, time:', Time.now_f
      start_good # sec's 6-9 open
      a.join
    end
  end
  
  context 'startup' do
    it 'should allow you to hit keys and change the setup'
    it 'should use the times to mute'
  end

  it 'should allow for real yaml files I guess'
  
end

