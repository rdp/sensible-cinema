require 'rubygems'
require 'spec/autorun'
require 'sane'
require_relative '../lib/overlayer'


describe OverLayer do
  
  def play file
    system("sndrec32 /play /close #{file}.wav") # this fails at times?
  end
  
  it 'should be able to mute' do
    # you shouldn't hear a beep
    OverLayer.mute!
    play("bad")
    sleep 2
    OverLayer.unmute!
  end
  
  context 'given you know when to start' do
    
    it 'should mute for 1s' do
      yaml = [:mutes => {3.0 => 6.0}]
      play("good") # sec's 0-3
      sleep 3
      play("bad") # sec's 3-6 muted
      sleep 3
      play("good") # sec's 6-9 open
    end
  end
  
  context 'startup' do
    it 'should allow you to hit keys and change the setup'
    it 'should use the times to mute'
  end

  it 'should allow for real yaml files I guess'
  
end
