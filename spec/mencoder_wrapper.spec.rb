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
    @out.should include("-ovc copy")
    @out.should include("-oac copy")
  end
  
  it "should accomodate for mutes" do
    @out.should match(/ -nosound/)
  end
  
  it "should use avi extension" do
    @out.should include(".avi ")
  end
  
  it "should concatenate them all together" do
    @out.should match(/mencoder.*\*/)
  end
  
  it "should delete any large, grabbed tmp file" do
    @out.should match(/del.*tmp/)
  end
  
  it "should delete any partials" do
    0.upto(5) do |n|
      @out.should  match(Regexp.new(/del.*#{n}/))
    end
  end
  
end