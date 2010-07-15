require 'rubygems'
require 'ffi'

module Mouse
  extend FFI::Library

  ffi_lib 'user32'
  ffi_convention :stdcall
  
  MOUSEEVENTF_MOVE = 1
  INPUT_MOUSE = 0
  MOUSEEVENTF_ABSOLUTE = 0x8000
  
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
  
  def self.jitter_forever_in_own_thread
    
    myinput = Mouse::Input.new
    myinput[:type] = Mouse::INPUT_MOUSE

    in_evt = myinput[:evt][:mi]

    in_evt[:mouse_data] = 0
    in_evt[:flags] = Mouse::MOUSEEVENTF_MOVE # | Mouse::MOUSEEVENTF_ABSOLUTE
    in_evt[:time] = 0
    in_evt[:extra] = 0
    in_evt[:dx] = 0
    in_evt[:dy] = 8 # just enough for VLC

    Thread.new {
      loop {
        in_evt[:dy] *= -1
        Mouse.SendInput(1, myinput, Mouse::Input.size)
        sleep 0.5
      }
    }
    
  end
    
end

Mouse::jitter_forever_in_own_thread.join if $0 == __FILE__