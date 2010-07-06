require 'rubygems'
require 'sane'
require 'win32api'
raise 'only jruby supported, as it looks just too messy in normal ruby' unless OS.java?

class KeyboardInput

 def initialize fella
  @fella = fella
 end

 def start_thread
  Thread.new { loop { 
    print get_line_printout
    sleep 1
   } }
 end

 def get_line_printout
    time = @fella.cur_time
    seconds = time % 60
    minutes = time.to_i / 60
    "\b"*100 + "Current time: %d:%02d " % [minutes, seconds]
  end

 def getch
  @getch ||= Win32API.new('crtdll', '_getch', [], 'L')
  @getch.call
 end

 def handle_keystrokes_forever
   while(ch = getch)
     puts 'got key', ch 
     return if ch.in? [3, 113] # ctrl+c, q
   end
 end

end

if $0 == __FILE__
  class Go
    @time = 55  
  def self.cur_time
      @time += 1
end
end

  a = KeyboardInput.new Go
  a.start_thread
  a.handle_keystrokes_forever
end