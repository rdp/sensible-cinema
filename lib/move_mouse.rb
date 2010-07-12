require 'ffi'

module Win
  extend FFI::Library

  ffi_lib 'user32'
  ffi_convention :stdcall
  
  MOUSEEVENTF_MOVE = 1
  INPUT_MOUSE = 0
  
  class MouseInput < FFI::Struct
    layout :dx, :long,
           :dy, :long,
           :mouse_data, :ulong,
           :flags, :ulong,
           :time, :ulong,
           :extra, :ulong
  end
  class InputEvent < FFI::Union
    layout :mi, MouseInput
  end 
  class Input < FFI::Struct
    layout :type, :ulong,
           :evt, InputEvent
  end
  
  # UINT SendInput(UINT nInputs, LPINPUT pInputs, int cbSize);
  attach_function :SendInput, [ :uint, :pointer, :int ], :uint
end

myinput = Win::Input.new
myinput[:type] = Win::INPUT_MOUSE

in_evt = myinput[:evt][:mi]

in_evt[:dx] = ARGV[0].to_i
in_evt[:dy] = ARGV[1].to_i
in_evt[:mouse_data] = 0
in_evt[:flags] = Win::MOUSEEVENTF_MOVE
in_evt[:time] = 0
in_evt[:extra] = 0

Win.SendInput(10, myinput, Win::Input.size)