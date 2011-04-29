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
require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/mouse'

p 'dont move the mouse!'

describe Mouse do

  it "should move it a couple times" do
    old = Mouse.total_movements
    begin
    Timeout::timeout(2) {
      Mouse::jitter_forever_in_own_thread.join
    }
    rescue Timeout::Error
    end
    Mouse.total_movements.should be > old
  end
  
  it "should not move it if the user does" do
    old = Mouse.total_movements
    begin
    Timeout::timeout(2) {
      Mouse::jitter_forever_in_own_thread
      x = 1
      loop {java.awt.Robot.new.mouse_move(500 + (x+=1),500); sleep 0.1; }
    }
    rescue Timeout::Error
    end
    Mouse.total_movements.should == old + 1
  end
  
  it "should be able to left mouse click" do
    Mouse.left_mouse_button_state.should be :up
    Mouse.left_mouse_down!
    Mouse.left_mouse_button_state.should be :down
    Mouse.left_mouse_up!
    Mouse.left_mouse_button_state.should be :up
  end
  
  it "should be able to click" do
    Mouse.left_mouse_button_state.should be :up
    Mouse.single_click_left_mouse_button
    Mouse.left_mouse_up!
    Mouse.left_mouse_up!
    Mouse.left_mouse_button_state.should be :up
  end

end