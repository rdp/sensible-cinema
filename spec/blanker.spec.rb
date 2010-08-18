require File.dirname(__FILE__) + '/common'
require_relative '../lib/blanker.rb'

describe Blanker do

  before(:each) do
    Blanker.startup  
  end
  
  after(:each) do
    Blanker.shutdown
  end

  it "should be able to blank then unblank" do
    Blanker.blank_full_screen! 23
    sleep 2
    Blanker.unblank_full_screen!
  end
  
  it "should be able to blank several times" do
    3.times {
      Blanker.blank_full_screen! ''
      Blanker.unblank_full_screen!
    }
  end
  
  it "should be able to unblank several times I suppose" do
    3.times {
      Blanker.unblank_full_screen!
    }
  end
  
  describe "future work", :pending => true do
    
    it "should be able to blank certain coords"
    
    it "should have a background color optionally"
    
    it "should have a picture optionally"
    
  end
  
end