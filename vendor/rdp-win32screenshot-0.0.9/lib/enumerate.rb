require 'rubygems'
require './lib/win32/screenshot'
require 'pp'
sleep 3
p 'enumerating'
pp Win32::Screenshot::Util.windows_hierarchy true