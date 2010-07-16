require 'rubygems'
require 'sane'
require_relative 'common'
require_relative '../lib/blanker.rb'

describe Blanker do
  
  it "should be able to blank then unblank" do
    Blanker.blank_full_screen!
    sleep 1
    Blanker.unblank_full_screen!
  end
  
  describe "future work", :pending => true do
    
    it "should be able to blank certain sections"
    
  end
  
end