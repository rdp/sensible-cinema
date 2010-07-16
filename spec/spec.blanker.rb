require 'rubygems'
require 'sane'
require_relative 'common'
require_relative '../lib/blanker.rb'

describe Blanker do
  
  it "should be able to blank then unblank" do
    Blanker.blank_full_screen!
    sleep 3
    Blanker.unblank_full_screen!
  end
  
  it "should be able to blank several times" do
    3.times {
      Blanker.blank_full_screen!
      Blanker.unblank_full_screen!
    }
  end
  
  describe "future work", :pending => true do
    
    it "should be able to blank certain coords"
    
    it "should have a color optionally"
    
    it "should have a picture optionally"
    
  end
  
end