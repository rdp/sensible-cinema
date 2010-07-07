require 'rubygems'
require 'sane'
require 'Win32API'

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
    time    = @fella.cur_time
    minutes = time.to_i / 60
    seconds = time - minutes*60
    status  = @fella.status
    # scary hard coded values here...
    " " *50 + "\b"*150 + "Current time: %d:%04.1f %s" % [minutes, seconds, status]
 end

 def getch
  @getch ||= Win32API.new('crtdll', '_getch', [], 'L')
  @getch.call
 end

 def handle_keystrokes_forever
   raise 'only jruby supported, as it looks just too messy in normal ruby' unless OS.java?
   while(ch = getch)
     handle_keystroke ch
     return if ch.in? [3, 113] # ctrl+c, q -> exit
     # lodo handle arrow keys, too, which is a bit more complicated...
   end
 end

 def handle_keystroke ch
   string = "" << ch
   @fella.keyboard_input(string)
 end

end