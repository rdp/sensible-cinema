Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
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
            sleep 0.75
          else
            old_x = get_mouse.x
            old_y = get_mouse.y
            sleep 3
          end
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