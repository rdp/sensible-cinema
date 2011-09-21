require 'rubygems'
require './win32/screenshot'
require 'sane'
#sleep 2
p 'taking it'
p Win32::Screenshot::BitmapMaker.hwnd(/virtual/i).to_s(16)
Win32::Screenshot::BitmapMaker.capture_area( 0x30484, 0,0, 1000,1000) {|h,w,bits| File.binwrite(ARGV[0] || 'out.bmp', bits)}