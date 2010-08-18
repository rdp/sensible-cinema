require File.dirname(__FILE__) + '/common'
require_relative "../lib/ocr"

$OCR_NO_CACHE = true

describe OCR do
  
  it "should be able to output help output" do
    OCR.version.should_not be_blank
  end
  
  Dir['images/*[0-9].bmp'].each{ |file|
    it "should be able to OCR #{file}" do
      options = {}
      options[:should_invert] = true if file =~ /hulu/
      file =~ /(.)\.bmp/
      expected_digit = $1.to_i
      if OCR.identify_digit(File.binread(file), options) != expected_digit
        p "fail:" + file
        begin
          require 'ruby-debug'
          debugger
          OCR.identify_digit(File.binread(file), options)
        rescue LoadError
          puts 'unable to load ruby-debug'
        end
        fail
      end
    end
  }
  
  it "should be able to grab a colon" do
    pending "caring about colons" do
      OCR.identify_digit(File.binread("images/colon.bmp"), :might_be_colon => true).should == ":"
    end
  end
  
  it "should return nil if it can't identify a digit" do
    OCR.identify_digit(File.binread("images/black.bmp")).should be_nil
  end
  
end