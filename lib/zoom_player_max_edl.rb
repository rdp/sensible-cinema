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

require_relative 'edl_parser'

class ZoomPlayerMaxEdl
  
  def self.convert_to_edl_string specs, is_dvd
    raise 'needs timestamps_relative_to--or rather, ping me if you want this for file based' unless specs['timestamps_relative_to']
    combined = EdlParser.convert_incoming_to_split_sectors specs, add_this_many_to_end, add_this_many_to_beginning, splits
    combined2 = EdlParser.convert_to_dvd_nav_times combined
    
    out = ""
    track = specs['dvd_title_track']
    out += "DVDTitle(#{track})\n"
=begin
    DVDTitle(1)
    CutSegment("Start=27.389","End=32.209")
    CutSegment("Start=73.510","End=78.510")
    MuteAudio("From=39.389","Duration=41.389")
=end
    for (start, endy), type in combined2
      
      if type == :mute
        out += %!MuteAudio("From=#{start}","Duration=#{endy-start}")\n!
      elsif type == :blank
        out += %!CutSegment("Start=#{start}","End=#{endy}")\n!
      else
        raise
      end
  end
end
