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
     return if ch.in? [3, 113] # ctrl+c, q -> exit
     # lodo handle arrow keys, too, which is a bit more complicated...
     handle_keystroke ch
   end
 end

 def handle_keystroke ch
   string = "" << ch
   @fella.keyboard_input(string)
 end

end