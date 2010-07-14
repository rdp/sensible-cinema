require 'ffi'

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
  
  def toggle_mute
    # simulate pressing the mute key
    keybd_event(VK_VOLUME_MUTE, 0, 0, nil);
    keybd_event(VK_VOLUME_MUTE, 0, KEYEVENTF_KEYUP, nil);
  end

  # allow for Muter.toggle_mute
  extend self
  
end
