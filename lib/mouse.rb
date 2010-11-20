require 'rubygems'
require 'ffi'

module Mouse
  extend FFI::Library
  MouseInfo =  java.awt.MouseInfo

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
  class << self
    
    def jitter_forever_in_own_thread
      
      myinput = Mouse::Input.new
      myinput[:type] = Mouse::INPUT_MOUSE
  
      in_evt = myinput[:evt][:mi]
  
      in_evt[:mouse_data] = 0
      in_evt[:flags] = Mouse::MOUSEEVENTF_MOVE # | Mouse::MOUSEEVENTF_ABSOLUTE
      in_evt[:time] = 0
      in_evt[:extra] = 0
      in_evt[:dx] = 0
      in_evt[:dy] = 8 # just enough for VLC full screen...
  
      old_x = get_mouse.x
      old_y = get_mouse.y
      Thread.new {
        loop {
          cur_x = get_mouse.x
          cur_y = get_mouse.y
          if(cur_x == old_x && cur_y == old_y)
            @total_movements += 1
            in_evt[:dy] *= -1
            Mouse.SendInput(1, myinput, Mouse::Input.size)
            in_evt[:dy] *= -1
            sleep 0.05
            Mouse.SendInput(1, myinput, Mouse::Input.size)
            old_x = get_mouse.x
            old_y = get_mouse.y            
          else
            old_x = get_mouse.x
            old_y = get_mouse.y
          end
          sleep 0.75
        }
      }
      
    end
    def get_mouse
      MouseInfo.getPointerInfo.getLocation
    end
    
    attr_accessor :total_movements
  end
    
end
Mouse.total_movements = 0