require File.dirname(__FILE__) + "/common"
require_relative '../lib/mencoder_wrapper'

describe MencoderWrapper do

  it "should be able to convert" do  
    a = YAML.load_file "../zamples/edit_decision_lists/dvds/happy_feet.txt"
    out = MencoderWrapper.get_bat_commands a, "e:\\"
    out.should_not be nil
    out.should include("e:\\")
  end
end