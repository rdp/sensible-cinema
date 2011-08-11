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
require File.dirname(__FILE__) + "/common"
require_relative '../lib/auto_window_finder'

describe AutoWindowFinder do

  context "a browser window is open" do
    before do
      fake_window = ''
      def fake_window.exists?
        true
      end
      RAutomation::Window.stub!(:new).and_return(fake_window)
      
    end
    
    context "it is mentioned in a file" do
      
      before do
        out =  "files/edls/auto_url.txt"
        File.write out, %!"url" => "http://www.youtube.com/watch?v=xd12hR68sWM"!
      end
      
      it "should connect the two automagically" do
        AutoWindowFinder.search_for_url_match('files/edls').should == ["edls/auto_url.txt"]
      end
      
      it "should search automatically iff the player specifies it to"
      
      it "should not match if 2 exist"
      
    end
  
  
  end
    # so basically, if a browser window is "open" to such and such a url
  # and it is mentioned in a file
  # it should find it

  
end