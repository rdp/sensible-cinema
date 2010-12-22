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

require_relative '../lib/frame_accurate'
describe FrameAccurate do

String = <<EOL

[PACKET]
codec_type=video
stream_index=0
pts=N/A
pts_time=N/A
dts=132
dts_time=4.404404
duration=1
duration_time=0.033367
size=29030.000000
pos=4164842
flags=K
[/PACKET]
[PACKET]
codec_type=audio
stream_index=1
pts=105984
pts_time=4.416000
dts=105984
dts_time=4.416000
duration=768
duration_time=0.032000
size=768.000000
pos=4193880
flags=K
[/PACKET]
[PACKET]
codec_type=video
stream_index=0
pts=N/A
pts_time=N/A
dts=133
dts_time=4.437771
duration=1
duration_time=0.033367
size=28965.000000
pos=4194656
flags=_
[/PACKET]

EOL

  it "should parse strings" do
    FrameAccurate.parse(String).should == [[4.404404, true], [4.437771, false]]
  end

end
