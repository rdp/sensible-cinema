=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end
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