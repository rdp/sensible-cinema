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

  EdlParser::EDL_DIR.gsub!(/^.*$/, 'files/edls')
  
  context "a browser window is open" do
    before do
      fake_window = ''
      def fake_window.exist?
        true
      end
      def fake_window.text
        "www.youtube.com/watch?v=xd12hR68sWM"
      end
      RAutomation::Window.stub!(:new).and_return(fake_window)
    end
    
    context "it is mentioned in a file" do
      
      before do
        out =  "files/edls/auto_url.txt"
        File.write out, %!"url" => "http://www.youtube.com/watch?v=xd12hR68sWM"!
      end
      
      it "should connect the two automagically" do
        AutoWindowFinder.search_for_single_url_match().should == "files/edls/../edls/auto_url.txt"
      end
      
      it "should search automatically iff the player specifies it to" # ?
      
      it "should be able to find with browser and url" do
        FileUtils.mkdir_p 'temp/players'
        File.write('temp/players/go.txt', "window_title: !ruby/regexp /Chrome/")
        AutoWindowFinder.search_for_player_and_url_match('temp').should == "temp/players/go.txt"
        File.write('temp/players/go.txt', "window_title: !ruby/regexp /asdf/")
        RAutomation::Window.unstub!(:new)
        AutoWindowFinder.search_for_player_and_url_match('temp').should be nil
      end
      
    end
  
  
  end
   
  
end