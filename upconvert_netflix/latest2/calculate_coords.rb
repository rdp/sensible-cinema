require 'rubygems'
gem 'ffi'
require 'ffi'
begin
  require 'sane'
rescue LoadError
  require 'rubygems'
  require 'sane' # LODO
end
require_relative '../../lib/screen_tracker.rb'
require_relative './setup_directshow_filter_params'

player_description = "..\\..\\zamples\\players\\youtube\\normal_in_youtube.com.chrome.txt" # right path...
screen_tracker = ScreenTracker.new_from_yaml File.binread(player_description), nil
p screen_tracker.get_hwnd_loop_forever
p screen_tracker.get_coords_of_window_on_display
x,y,x2,y2 = screen_tracker.get_coords_of_window_on_display
# all right, except, for youtube, the y2 is too high, includes the red at the bottom 
# TODO cut off black edges too...why not, eh?
y2 -= 50
#require 'ruby-debug'
#debugger
p 'setting to', x, y, x2, y2
setter = SetupDirectshowFilterParams.new
setter.set_single_setting 'height', y2 - y
setter.set_single_setting 'width', x2 - x
setter.set_single_setting 'start_x', x
setter.set_single_setting 'start_y', x

screen_tracker.dump_bmps