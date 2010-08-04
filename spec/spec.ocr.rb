require File.dirname(__FILE__) + '/common'
require_relative "../lib/ocr"

describe OCR do
  
  it "should be able to output help output" do
    OCR.version.should_not be_blank
  end
  
  it "should be able to grab some digits" do
    for file in Dir['images/*[0-9].bmp']
      p file
      options = {}
      options[:should_invert] = true if file =~ /hulu/
      file =~ /(.)\.bmp/
      expected_digit = $1.to_i
      OCR.identify_digit(File.binread(file), options).should == expected_digit
    end
  end
  
  it "should be able to grab a colon" do
    OCR.identify_digit(File.binread("images/colon.bmp"), :might_be_colon => true).should == ":"
  end
  
  it "should return nil if it can't identify a digit" do
    OCR.identify_digit(File.binread("images/black.bmp")).should be_nil
  end
  
end