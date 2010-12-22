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

require_relative 'overlayer'
require_relative 'edl_parser'

class MplayerEdl
  def self.convert_to_edl specs, add_this_many_to_end = 0, add_this_many_to_beginning = 0
    # simple re-map.
    combined = EdlParser.convert_incoming_to_split_sectors specs, add_this_many_to_end, add_this_many_to_beginning
    out = ''
    map = {:mute => 1, :blank => 0}
    for start, endy, type in combined
      out += "#{start} #{endy} #{map[type]}\n"
    end
    out
  end
end