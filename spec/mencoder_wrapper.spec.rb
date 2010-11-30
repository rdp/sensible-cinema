require File.dirname(__FILE__) + "/common"
require_relative '../lib/mencoder_wrapper'

describe MencoderWrapper do

  before do
    @a = YAML.load_file "../zamples/edit_decision_lists/dvds/happy_feet.txt"
    @out = MencoderWrapper.get_bat_commands @a, "e:\\", 'to_here'
  end
  
  it "should be able to convert" do      
    @out.should_not be nil
    @out.should include("e:\\")
  end
  it "should use newline" do
    @out.should include("\n")
  end
  
  it "should use start and stop times" do
    @out.should include(" -ss ")
    @out.should include(" -endpos ")
  end
  
  it "should have what looks like a working mencoder command" do
    @out.should include("-avc copy")
  end
  
  it "should concatenate them all together" do
    @out.should match(/mencoder.*\*/)
  end
  
end