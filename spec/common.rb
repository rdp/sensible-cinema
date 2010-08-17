require 'rubygems'
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
require 'ffi-inliner'

module GetPid
  extend FFI::Library
  extend Inliner
  ffi_lib 'user32', 'kernel32'
  ffi_convention :stdcall
  attach_function :get_process_id_old, :GetProcessId, [ :ulong ], :uint
  
  attach_function :GetWindowThreadProcessId, [:ulong, :pointer], :uint


  def self.get_process_id_from_window hwnd
    out = FFI::MemoryPointer.new(:uint)
    GetWindowThreadProcessId(hwnd, out) # does translation automatically to ptr for us
    out.get_uint32(0) # read_uint
  end
  
  inline <<-CODE
  #include <windows.h>
  //#include <strsafe.h> // not available in mingw...

  void ErrorExit() 
  { 
    // Retrieve the system error message for the last-error code
    LPTSTR lpszFunction = "abcdef"; 
    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;
    DWORD dw = GetLastError(); 

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR) &lpMsgBuf,
        0, NULL );

    // Display the error message and exit the process
    printf("here1");
    lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT, 
        (lstrlen((LPCTSTR)lpMsgBuf) + lstrlen((LPCTSTR)lpszFunction) + 40) * sizeof(TCHAR)); 
    printf("here2");
    snprintf((LPTSTR)lpDisplayBuf, 
        LocalSize(lpDisplayBuf) / sizeof(TCHAR),
        TEXT("%s failed with error %d: %s"), 
        lpszFunction, dw, lpMsgBuf); 
            printf("here3");
            MessageBox(NULL, (LPCTSTR)lpDisplayBuf, TEXT("Error"), MB_OK); 
    printf("here4 ");

    LocalFree(lpMsgBuf);
    LocalFree(lpDisplayBuf);
  //  ExitProcess(dw); 
  }
  
  
  CODE
  
end