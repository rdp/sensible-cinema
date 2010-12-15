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
require_relative '../lib/keyboard_input'

describe KeyboardInput do

  class Go
    @time = 58
    def self.cur_time
      @time += 1
    end

    def self.got
      @got
    end

    @muted = true
    class << self
      attr_accessor :muted
    end

    def self.status
      @muted = !@muted
      if @muted
        "muted"
      else
        "unmuted"
      end
    end

    def self.keyboard_input input
      @got = input
    end
  end

  before do
    @a = KeyboardInput.new Go
    Go.muted = true
  end

  it "should display on one line" do
    @a.get_line_printout.should include("\b\b\b")
  end

  it "should display whether muted or not" do
    @a.get_line_printout.should include("unmuted")
    @a.get_line_printout.should_not include("unmuted")
  end

  it "should translate keys to characters" do
    @a.handle_keystroke 77
    Go.got.should == "M"
    @a.handle_keystroke 109
    Go.got.should == "m"
  end

end
