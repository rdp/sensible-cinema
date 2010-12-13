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
    require 'rubygems'
require 'sane'
require 'Win32API'

# does the jruby check inline

class KeyboardInput

 def initialize fella
  @fella = fella
 end

 def start_thread
  Thread.new { loop { 
    print get_line_printout
    sleep 0.1
   } }
 end

 def get_line_printout
    status  = @fella.status
    # scary hard coded values here...
    " " * 20 + "\b"*150 + status
 end

 def getch
  @getch ||= Win32API.new('crtdll', '_getch', [], 'L')
  @getch.call
 end

 def handle_keystrokes_forever
   raise 'only jruby supported, as it looks just too messy in normal ruby' unless OS.java?
   while(ch = getch)
     exit if ch == 3 # ctrl+c
     # lodo handle arrow keys, too, which is a bit more complicated...
     handle_keystroke ch
   end
 end

 def handle_keystroke ch
   string = "" << ch
   @fella.keyboard_input(string)
 end

end