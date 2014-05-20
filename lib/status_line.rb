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

# does the jruby check inline

class StatusLine

 def initialize fella
  @fella = fella
 end
 
 @keep_going = true

 def start_thread
  @keep_going = true
  Thread.new { 
    while(@keep_going)
      print get_line_printout
      sleep 0.1
    end
    puts 'exiting status line'
   }
 end
 
 def shutdown
   @keep_going = false
 end

 def get_line_printout
    status = "status line:" + @fella.status
    # some scary hard coded values here...XXXX
    " " * 20 + "\b"*150 + status + "\n"
 end

end
