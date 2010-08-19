require File.dirname(__FILE__) + '/common'
require_relative "../lib/ocr"
require 'benchmark'

$OCR_NO_CACHE = true

describe OCR do
  
  it "should be able to output help output" do
    OCR.version.should_not be_blank
  end
  
  Dir['images/*[0-9].bmp'].sort_by{|f| File.stat(f).mtime}.reverse.each{ |file|
    it "should be able to OCR #{file}" do
      options = {}
      options[:should_invert] = true if file =~ /hulu/
      file =~ /(.)\.bmp/
      expected_digit = $1.to_i
      got_digit = OCR.identify_digit(File.binread(file), options)
      if got_digit != expected_digit
        p "fail:" + file
        begin
          require 'ruby-debug'
          debugger
          OCR.identify_digit(File.binread(file), options)
        rescue LoadError
          puts 'unable to load ruby-debug'
        end
        got_digit.should == expected_digit
      end
    end
  }
  
  it "should be able to grab a colon" do
    pending "caring about colons" do
      OCR.identify_digit(File.binread("images/colon.bmp"), :might_be_colon => true).should == ":"
    end
  end
  
  def read_digit
    OCR.identify_digit(File.binread("images/youtube_3_0.bmp"))
  end
  
  it "should return nil if it can't identify a digit" do
    OCR.identify_digit(File.binread("images/black.bmp")).should be_nil
  end
  
  context "cache" do
  
   before do
     OCR.clear_cache!
     $OCR_NO_CACHE = false
   end
  
   after do
     $OCR_NO_CACHE = true
   end
  
    it "should cache results from one time to the next" do
      original_time = Benchmark.realtime { read_digit }
      new_time = Benchmark.realtime { 3.times { read_digit } }
      new_time.should be < original_time
    end
    
    it "should not cache results for failed reads" do
      original_time = Benchmark.realtime { OCR.identify_digit(File.binread("images/black.bmp")) }
      new_time = Benchmark.realtime { 3.times { OCR.identify_digit(File.binread("images/black.bmp"))} }
      new_time.should be > original_time
    end    
    
    it "should serialize creating a cache file" do
      Pathname.new(OCR::CACHE_FILE).should_not exist
      OCR.serialize_cache_to_disk
      Pathname.new(OCR::CACHE_FILE).should exist
    end
    
    it "should use the cache file to speed things up on startup" do
      long = Benchmark.realtime { read_digit }
      OCR.serialize_cache_to_disk
      OCR::CACHE.clear
      long2 = Benchmark.realtime { read_digit }
      OCR.unserialize_cache_from_disk
      short = Benchmark.realtime { 3.times { read_digit } }
      long.should be > short
      long2.should be > short
    end
    
  end
  
end