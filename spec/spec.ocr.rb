require File.dirname(__FILE__) + '/common'
require_relative "../lib/ocr"

describe OCR do
  
  it "should be able to output help output" do
    OCR.version.should_not be_blank
  end
  
  it "should be able to grab some digits" do
    OCR.identify_digit(File.binread "images/4.bmp").should == "4"    
  end
  
  it "should be able to grab a colon" do
    OCR.identify_digit(File.binread("images/colon.bmp"), true).should == ":"
  end
  
  
end