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
require 'rubygems' # ugh
require 'ffi'
require 'sane'
require_relative 'mouse'

module Muter
  # from msdn on keybd_event ...
  
  VK_VOLUME_DOWN = 0xAE
  VK_VOLUME_UP = 0xAF
  VK_VOLUME_MUTE = 0xAD
  KEYEVENTF_KEYUP = 2
  
  extend FFI::Library
  ffi_lib 'user32'
  ffi_convention :stdcall

  attach_function :keybd_event, [ :uchar, :uchar, :int, :pointer ], :void
  
  def hit_mute_key
    # simulate pressing the mute key
    keybd_event(VK_VOLUME_MUTE, 0, 0, nil)
    keybd_event(VK_VOLUME_MUTE, 0, KEYEVENTF_KEYUP, nil)
  end
  
  def hit_volume_up_key
    keybd_event(VK_VOLUME_UP, 0, 0, nil)
    keybd_event(VK_VOLUME_UP, 0, KEYEVENTF_KEYUP, nil)
  end
  
  def hit_volume_down_key
    keybd_event(VK_VOLUME_DOWN, 0, 0, nil)
    keybd_event(VK_VOLUME_DOWN, 0, KEYEVENTF_KEYUP, nil)
  end
  
  @@use_mouse = false # ai ai
  
  def mute!
    #unmute! # just in case...somehow this was causing problems...windows 7 perhaps? VLC? 
    # anyway we just use a toggle for now...dangerous but works, if barely
    if !@@use_mouse
      hit_mute_key
    else
      Mouse.single_click_left_mouse_button
    end
  end

  # TODO better for doze 7...
  def unmute!
    if !@@use_mouse
      hit_mute_key # Windows XP...
      hit_volume_down_key
      hit_volume_up_key
    else
      Mouse.single_click_left_mouse_button
    end
    
  end
      
  # allow for Muter.xxx
  extend self
  
end
