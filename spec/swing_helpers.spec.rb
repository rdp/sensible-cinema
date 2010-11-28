require File.expand_path(File.dirname(__FILE__) + '/common')
require 'os'
require_relative '../lib/swing_helpers'
module SensibleSwing
describe SensibleSwing do

  it "should close its modeless dialog" do
   
   dialog = ModeLessDialog.new("Is this modeless?")
   dialog = ModeLessDialog.new("Is this modeless?\nSecond lineLL")
   dialog = ModeLessDialog.new("Is this modeless?\nSecond lineLL\nThird line too!")
   dialog = ModeLessDialog.new("Can this take very long lines of input, like super long?")
   #dialog.dispose # should get here :P
   # let them close it :P
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