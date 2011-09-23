require 'rubygems'
require './win32/screenshot'
require 'sane'
#sleep 2
p 'taking it'
#p Win32::Screenshot::BitmapMaker.hwnd(/virtual/i).to_s(16)
name = ARGV[0] || 'out.bmp'
Win32::Screenshot::BitmapMaker.capture_area( Win32::Screenshot::BitmapMaker.hwnd(/virtual/i), 0,0,1000,1000) {|h,w,bits| File.binwrite(name, bits)}
Win32::Screenshot.window( /virtual/i, 0) {|h,w,bits| File.binwrite('1' +name, bits)}
p name