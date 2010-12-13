=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
=end
require_relative 'overlayer'

class MplayerEdl
  def self.convert_to_edl specs
    out = ""
    for type, metric in {"mutes" => 1, "blank_outs" => 0}
      specs[type].each{|start, endy, other|
      out += "#{OverLayer.translate_string_to_seconds start} #{OverLayer.translate_string_to_seconds endy} #{metric}\n"
    }
    end
    out
    
  end
end