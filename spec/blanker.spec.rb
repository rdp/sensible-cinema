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
    Blanker.blank_full_screen! "blank then unblank"
    sleep 0.5
    Blanker.unblank_full_screen!
  end
  
  it "should be able to blank then unblank several times" do
    3.times {
      Blanker.blank_full_screen! 'unblank several times'
      Blanker.unblank_full_screen!
    }
  end
  
  it "should be able to unblank several times in a row I suppose" do
    3.times {
      Blanker.unblank_full_screen!
    }
  end
  
  describe "future work", :pending => true do
    
    it "should be able to blank certain coords"
    
    it "should have a background color specificable"
    
    it "should have a picture overlay optionally"
    
  end
  
end