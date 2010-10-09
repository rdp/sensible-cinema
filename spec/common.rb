by -vrequire 'rubygems'
begin
  require 'rspec' # rspec2
rescue LoadError
  require 'spec' # rspec1
  require 'spec/autorun'
end

# some useful utilities...

require 'sane'
require 'benchmark'
Thread.abort_on_exception = true
require 'timeout'
require 'fileutils'

Dir.chdir File.dirname(__FILE__) # always run from the right dir...

begin
  require 'hitimes'
  Benchmark.module_eval {
    def self.realtime
      Hitimes::Interval.measure { yield }
    end
  }
rescue LoadError
  if RUBY_PLATFORM =~ /java/
    require 'java'
    Benchmark.module_eval {
      def self.realtime
        beginy = java.lang.System.nano_time
        yield
        (java.lang.System.nano_time - beginy)/1000000000.0
      end
    }
  else
    puts 'no hitimes available...'
  end
    
end

#for file in Dir[File.dirname(__FILE__) + "/../lib/*"] do
  # don't load them here in case one or other fails...
  # require file
#end

require 'ffi'

module GetPid
  extend FFI::Library
  ffi_lib 'user32', 'kernel32'
  ffi_convention :stdcall
  attach_function :get_process_id_old, :GetProcessId, [ :ulong ], :uint
  
  attach_function :GetWindowThreadProcessId, [:ulong, :pointer], :uint

  def self.get_process_id_from_window hwnd
    out = FFI::MemoryPointer.new(:uint)
    GetWindowThreadProcessId(hwnd, out) # does translation automatically to ptr for us
    out.get_uint32(0) # read_uint
  end
  
end