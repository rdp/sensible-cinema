require File.dirname(__FILE__) + "/common"
require_relative '../lib/mplayer_edl'

describe MplayerEdl do
  
  { "mutes" => {5=> 7}, "blank_outs" => {6=>7} }
  it "should translate verbatim" do
    a = MplayerEdl.convert_to_edl({ "mutes"=>{105=>145, "46:33.5"=>2801}, "blank_outs" => {6 => 7} } )
    # 0 for skip, 1 for mute
    a.should == <<EOL
105.0 145.0 1
2793.5 2801.0 1
6.0 7.0 0
EOL
  end
end