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
require_relative '../lib/youtube_edl'

#http://rogerdpack.t28.net/sensible-cinema/youtube_edl/yo?mute_start=2&mute_end=7&skip_start=10&skip_end=20&youtube_video_id=ylLzyHk54Z0
describe YoutubeEdl do

  it "should be able to convert" do  
    a = YAML.load_file "../zamples/edit_decision_lists/dvds/happy_feet.txt"
  end

end
