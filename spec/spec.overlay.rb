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
  end
  
  
end