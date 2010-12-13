=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
=end
require File.dirname(__FILE__) + '/common'
require_relative '../lib/blanker.rb'

describe Blanker do

  before(:each) do
    Blanker.startup  
  end
  
  after(:each) do
    Blanker.shutdown
  end

  it "should be able to blank then unblank" do
    Blanker.blank_full_screen! "blank then unblank"
    sleep 0.5
    Blanker.unblank_full_screen!
  end
  
  it "should be able to blank then unblank several times" do
    3.times {
      Blanker.blank_full_screen! 'unblank several times'
      Blanker.unblank_full_screen!
    }
  end
  
  it "should be able to unblank several times in a row I suppose" do
    3.times {
      Blanker.unblank_full_screen!
    }
  end
  
  describe "future work", :pending => true do
    
    it "should be able to blank certain coords"
    
    it "should have a background color specificable"
    
    it "should have a picture overlay optionally"
    
  end
  
end