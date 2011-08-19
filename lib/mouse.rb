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
require 'ffi'
require 'java'

module Mouse
  extend FFI::Library
  MouseInfo =  java.awt.MouseInfo

  ffi_lib 'user32'
  ffi_convention :stdcall
  
  MOUSEEVENTF_MOVE = 1
  INPUT_MOUSE = 0
  MOUSEEVENTF_ABSOLUTE = 0x8000
  MOUSEEVENTF_LEFTDOWN = 0x0002
  MOUSEEVENTF_LEFTUP   = 0x0004
  
  
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

  # poller...
  attach_function :GetAsyncKeyState, [:int], :uint
  
  class << self
    
    def jitter_forever_in_own_thread
  
      old_x = get_mouse_location.x
      old_y = get_mouse_location.y
      Thread.new {
        loop {
          cur_x = get_mouse_location.x
          cur_y = get_mouse_location.y
          move_y = 8 # just enough for VLC when full screened...
          if(cur_x == old_x && cur_y == old_y)
            @total_movements += 1
            # blit it up
            move_mouse_relative(0, move_y *= -1)
            move_mouse_relative(0, move_y *= -1)
            sleep 0.05
            # move it back
            move_mouse_relative(0, move_y *= -1)
            old_x = get_mouse_location.x
            old_y = get_mouse_location.y            
            sleep 0.75
          else
            # user has been moving the mouse around, so we don't need to, to not annoy them
            old_x = get_mouse_location.x
            old_y = get_mouse_location.y
            sleep 3
          end
        }
      }
      
    end
    
    def move_mouse_relative dx, dy
      myinput = Mouse::Input.new
      myinput[:type] = Mouse::INPUT_MOUSE
      in_evt = myinput[:evt][:mi]
      in_evt[:mouse_data] = 0 # null it out
      in_evt[:flags] = Mouse::MOUSEEVENTF_MOVE
      in_evt[:time] = 0
      in_evt[:extra] = 0
      in_evt[:dx] = dx
      in_evt[:dy] = dy
      SendInput(1, myinput, Mouse::Input.size)
    end
    
    def single_click_left_mouse_button
      left_mouse_down!
      left_mouse_up!
      p "CLICKED LEFT MOUSE BUTTON"
    end
    
    def left_mouse_down!
      send_left_mouse_button MOUSEEVENTF_LEFTDOWN
    end
    
    def left_mouse_up!
      send_left_mouse_button MOUSEEVENTF_LEFTUP
    end

    VK_LBUTTON = 0x01 # mouse left button for GetAsyncKeyState (seeing if mouse down currently or not)
    
    def left_mouse_button_state
      GetAsyncKeyState(VK_LBUTTON) # ignore a first response, which also tells us if it has changed at all since last call
      if GetAsyncKeyState(VK_LBUTTON) == 0 # zero means up
        :up
      else
        :down
      end
    end
    
    def get_mouse_location
      MouseInfo.getPointerInfo.getLocation
    end
    
    attr_accessor :total_movements
    
    private
    
    def send_left_mouse_button action_type
      myinput = Mouse::Input.new
      myinput[:type] = Mouse::INPUT_MOUSE
      in_evt = myinput[:evt][:mi]
      in_evt[:flags] = action_type
      SendInput(1, myinput, Mouse::Input.size)
    end

    
  end
    
end
Mouse.total_movements=0 # ruby is a bit freaky with these...