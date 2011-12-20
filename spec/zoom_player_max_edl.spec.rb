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
require_relative '../lib/zoom_player_max_edl'

describe ZoomPlayerMaxEdl do

  it "should create an edl" do
    specs = {"name"=>"national treasure", "mutes"=>[], "blank_outs"=>[["01:00:00.0", "01:00:10.0", "violence", "of some sort"]], "dvd_nav_packet_offset"=>[0.4, 0.6143], "volume_name"=>"NATIONAL_TREASURE", "disk_unique_id"=>"91a5aeec|5178a204", "dvd_title_track"=>"1", "dvd_title_track_length"=>7856.8, "dvd_start_offset"=>"0.28", "timestamps_relative_to"=>["dvd_start_offset", "29.97"]}
    out = ZoomPlayerMaxEdl.convert_to_edl_string specs
    assert out == "DVDTitle(1)\nCutSegment(\"Start=3596.6178964036\",\"End=3606.60790639361\")\n"
  end
  
end