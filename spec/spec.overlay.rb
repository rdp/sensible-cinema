require 'rubygems'
require 'spec/autorun'

describe 'overlayer' do
  
  
  context 'given a yaml file' do
    before do
      @yaml = [{:start => 1.0, :end => 2.0}]
    end
    
    it 'should mute once' do
      Overlayer.overlay @yaml, 0
    end
    
    it 'should mute for 1s'
  end
  
  context 'startup' do
    it 'should allow you to hit keys and change the setup'
    it 'should use the times to mute'
  end
  
  
end