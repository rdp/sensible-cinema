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
require 'os'
require_relative '../lib/swing_helpers'
module SensibleSwing
describe SensibleSwing do

  it "should close its modeless dialog" do
   
   dialog = NonBlockingDialog.new("Is this modeless?")
   dialog = NonBlockingDialog.new("Is this modeless?\nSecond lineLL")
   dialog = NonBlockingDialog.new("Is this modeless?\nSecond lineLL\nThird line too!")
   dialog = NonBlockingDialog.new("Can this take very long lines of input, like super long?")
   #dialog.dispose # should get here :P
   # let user close it :P
  end
  
  it "should be able to convert filenames well" do
    if OS.windows?
      "a/b/c".to_filename.should == "a\\b\\c"
    else
      "a/b/c".to_filename.should == "a/b/c"
    end
  end

end
end
puts 'close the windows...'