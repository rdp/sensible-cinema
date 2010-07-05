require 'rubygems'
require 'spec/autorun'
require 'sane'
require_relative '../lib/overlayer'


describe OverLayer do
  
  
  context 'given you know when to start' do
    
    before do
      @yaml = [{:start => 1.0, :end => 2.0}]
    end
    
    it 'should mute once' do
      OverLayer.mute!
      system("sndrec32 /play /close beep.wav")
      sleep 3
      OverLayer.unmute!
    end
    
    it 'should mute for 1s'
  end
  
  context 'startup' do
    it 'should allow you to hit keys and change the setup'
    it 'should use the times to mute'
  end

  it 'should allow for real yaml files I guess'
  
end