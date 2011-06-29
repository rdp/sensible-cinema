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
require_relative '../lib/media_info_parser'

describe MediaInfoParser do
  
  it "should parse" do
    out = MediaInfoParser.parse_with_convert_command(File.read('tsmuxer.output'), "G:\\Video\\Sintel_NTSC\\title01.mkv")
    out.should == "MUXOPT --no-pcr-on-video-pid --new-audio-pes --vbr  --vbv-len=500\nV_MPEG-2, \"G:\\Video\\Sintel_NTSC\\title01.mkv\", fps=29.97, track=1, lang=eng\nA_AC3, \"G:\\Video\\Sintel_NTSC\\title01.mkv\", track=2, lang=eng"
    print out
  end
  
end