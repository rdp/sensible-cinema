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
  
  it "should use newline every line" do
    @out.should include("\n")
    @out.should_not match(/mencoder.*mencoder/)
    @out.should_not match(/del.*del/)
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
    # mutes by silencing...seems reasonable, based on the Family Law
    @out.should match(/ -af volume=-200/)
  end
  
  it "should use avi extension" do
    @out.should include(".avi ")
  end
  
  it "should concatenate (merge) them all together" do
    @out.should match(/mencoder.*ovc.*oac/)
  end
  
  it "should delete any large, grabbed tmp file" do
    @out.should match(/del.*tmp/)
  end
  
  it "should delete all partials" do
    0.upto(5) do |n|
      @out.should match(Regexp.new(/del.*#{n}/))
    end
    # should delete the right numbers, too
    @out.should_not match(/del to_here.avi.avi.0/)
  end
  
  def setup
    @settings = {"mutes"=>{1=>2, 7=>12}, "blank_outs"=>{"2"=>"3"}}
    @out = MencoderWrapper.get_bat_commands @settings, "e:\\", 'to_here.avi'
  end
  
  it "should not insert an extra pause if a mute becomes a blank" do
    setup
    @out.should_not match(/-endpos 0.0/)
    File.write('out.bat', @out)
  end
  
  it "should not include blank sections" do
    setup
    @out.should_not include('-ss 2.0 -endpos 1.0')
    # and not be freaky by setting the end to nosound
    @out.should_not match(/-endpos \d{6}.*volume/)
  end
  
  it "should lop off a fraction of a second per segment, as per wiki instructions" do
    setup
    @out.should match(/-endpos 0.999/)
  end
  
  it "should not have doubles" do
    setup  
    @out.scan(/-endpos.*-o to_here.avi.avi.1/).length.should == 1
    @out.scan(/-endpos.*-o to_here.avi.avi.2/).length.should == 1
  end
  
  it "should allow for subsections" do
     settings = {"mutes"=>{15=>20, 30 => 35}}
     out = MencoderWrapper.get_bat_commands settings, "e:\\", 'to_here.avi', '00:14', '00:25'
     out.should_not include("35")
     out.should_not include(" 0 ")
     out.should include("14")
     out.should_not include("99999")
     out.should include("-ss 14.0 -endpos 0.999")
  end
  
  it "should raise if you focus down into nothing" do
    setup
    proc { MencoderWrapper.get_bat_commands @settings, "e:\\", 'to_here', '00:14', '00:15'}.should raise_error(/unable/)
  end
  
end