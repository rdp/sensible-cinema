require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/edl_parser'

describe EdlParser do
  
  E = EdlParser
  
  it "should parse" do
    E.parse_string('"a" => "3"').should ==  {"a"=>"3", "mutes"=>[], "blank_outs"=>[]}
  end
  # LODO is blank_outs the best term for it?
  it "should get mutes and blank_outs" do
   string = File.read(__dir__ + "/../zamples/edit_decision_lists/example_edit_decision_list.txt")
   expected = 
   {
    "mutes"=>[["00:00:01", "00:00:02"], 
    ["00:00:01", "00:00:02", "profanity", "dang"], 
    ["01:01:00", "01:02:00"]], 
    "blank_outs"=>[["01:01:00", "01:02:00", "nudity", "5"], 
    ["00:03:03.5", "00:03:04.5"], 
    ["01:01:00", "01:02:00", "profanity", "bodily function 1"]], 
    "missing_content"=>"this doesn't list some mild name calling", 
    "title"=>"Forever Strong", "source"=>"Hulu", "url"=>"http://www.byutv.org/watch/1790-100", 
    "whatever_else_you_want"=>"this is the old version of the film"
   }
   require '_dbg'
   E.parse_string(string).should == expected
  
  end
  
  it "should extract digits well" do
    out = ["00:00:01.1", "00:00:01"]
    EdlParser.extract_entry!(out).should == ["00:00:01.1", "00:00:01"]
    out.should == []    
  end
  
  it "should extract digits plus 'stuff' well" do
    out = ["1:01", "1:01", "a", "2:01", "2:02", "b"]
    EdlParser.extract_entry!(out).should == ["1:01", "1:01", "a"]
    EdlParser.extract_entry!(out).should == ["2:01", "2:02", "b"]
  end
  
  it "should raise if the first two aren't digits" do
    proc { EdlParser.extract_entry!(["a"])}.should raise_exception
  end
  
  it "should detect timestamps well" do
   t = EdlParser::TimeStamp
   "2:01".should match(t)
   "1:01.5".should match(t)
   "00:00:00.5".should match(t)
   "00:00:00".should match(t)
   "5".should_not match(t)
   "category".should_not match(t)
  end
  
end