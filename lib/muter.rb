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
require 'os'
require_relative 'jruby-swing-helpers/lib/simple_gui_creator/mouse_control'

if OS.x?

module Muter
  def mute!
    system(%!osascript -e "set volume with output muted"!)
  end
  def unmute!
    system(%!osascript -e "set volume without output muted"!)
  end
  def hit_volume_up_key
    system(%!osascript -e "set volume output volume (output volume of (get volume settings) + 5) --100%"!)
  end
  def hit_volume_down_key
    system(%!osascript -e "set volume output volume (output volume of (get volume settings) - 5) --100%"!)
  end
  # allow for Muter.xxx
  extend self
end

elsif OS.linux?

module Muter
  def mute!
    system("amixer sset 'Master' 50%")
  end
  def unmute!
   system("amixer -D pulse set Master 1+ toggle") # http://askubuntu.com/questions/65764/how-do-i-toggle-sound-with-amixer/286437#286437 yikes
  end
  extend self
end

else
 
# assume windows


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
    p 'hitting up volume key'
    keybd_event(VK_VOLUME_UP, 0, 0, nil)
    keybd_event(VK_VOLUME_UP, 0, KEYEVENTF_KEYUP, nil)
  end
  
  def hit_volume_down_key
    p 'hitting down volume key'
    keybd_event(VK_VOLUME_DOWN, 0, 0, nil)
    keybd_event(VK_VOLUME_DOWN, 0, KEYEVENTF_KEYUP, nil)
  end
  
  def mute!
    #unmute! # just in case...somehow this was causing problems...windows 7 perhaps? VLC? 
    # anyway we just use a toggle for now...dangerous but works hopefully...
    if @@use_mouse_click
      Mouse.single_click_left_mouse_button
    else
      hit_mute_key
    end
  end
  
  @@use_mouse_click = false # TODO if ever use this then...umm...fix it for mac too?

  # LODO better for doze 7/xp
  def unmute!
    if @@use_mouse_click
      Mouse.single_click_left_mouse_button
    elsif @@use_static_on_top
      stop_playing_static
    elsif @@use_down_volume_button
      @@use_down_volume_button_number.times { hit_volume_up_key }
    else
      hit_mute_key # Windows XP...
      hit_volume_down_key
      hit_volume_up_key
    end
    
  end
      
  # allow for Muter.xxx
  extend self
  
end

end
