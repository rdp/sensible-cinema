# unused anymore...

class ShutdownHook 
  include java.lang.Runnable
          	def initialize( &block)
          		super()
          		@block=block
          	end
              def run
                  @block[]
              end
end
          
def at_exit2( &block)
   hook = ShutdownHook.new( &block)
   java.lang.Runtime.getRuntime.addShutdownHook(java.lang.Thread.new( hook ))
end

# LODO add button if I would ever find this useful...
def kill_processes
  
  if OS.windows?
    # this prevents people from having two processes going at once...kind of like queueing them up...
    # system_original("taskkill /f /im mencoder.exe 2>NUL") # todo...is there a better way?
    # system_original("taskkill /f /im ffmpeg.exe 2>NUL")
    # system_original("taskkill /f /im smplayer.exe 2>NUL")
    # system_original("taskkill /f /im mplayer.exe 2>NUL")
  end
end

at_exit2 {
  kill_processes # just in case
}
