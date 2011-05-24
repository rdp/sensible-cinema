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
require 'rubygems'
require 'rspec' # rspec2

# some useful utilities...

require 'sane'
require 'benchmark'
Thread.abort_on_exception = true
require 'timeout'
require 'fileutils'
require 'pathname'
require 'java' if OS.java?

Dir.chdir File.dirname(__FILE__) # always run from the right dir...
autoload :YAML, 'yaml'

begin
  require 'hitimes'
  Benchmark.module_eval {
    def self.realtime
      Hitimes::Interval.measure { yield }
    end
  }
rescue LoadError
  if OS.java?
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

if OS.windows?
  # I guess they all don't need this...
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

end
