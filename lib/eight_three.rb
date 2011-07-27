require 'ffi'

module EightThree
  extend FFI::Library
  ffi_lib 'kernel32'
  ffi_convention :stdcall
  
=begin
DWORD WINAPI GetShortPathName(
  __in   LPCTSTR lpszLongPath,
  __out  LPTSTR lpszShortPath,
  __in   DWORD cchBuffer
);
=end

  attach_function :path_to_8_3, :GetShortPathNameA, [:pointer, :pointer, :uint], :uint
  def self.convert_path_to_8_3 path
    out = FFI::MemoryPointer.new 256 # bytes
    path_to_8_3(path, out, out.length)
    out.get_string
  end

end
