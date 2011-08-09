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

# numbers are all right, except, for youtube "within a user window", when the y2 is too high, and includes the red at the bottom 
y2 -= 50
setter = SetupDirectshowFilterParams.new
setter.set_single_setting 'height', y2 - y
setter.set_single_setting 'width', x2 - x
setter.set_single_setting 'start_x', x
setter.set_single_setting 'start_y', y
p 'set it to', x, y, x2, y2
