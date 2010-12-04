require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/edl_parser'

describe EdlParser do
  
  E = EdlParser
  
  it "should parse" do
    E.parse_string('"a" => "3"').should == {"a" => "3"}
  end
  
  it "should get mutes and blank_outs" do
   string = File.read(__dir__ + "/../zamples/edit_decision_lists/example_edit_decision_list.txt")
   E.parse_string(string).should == 
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
  
  end
  
  it "should extract digits well" do
    out = ["00:00:01.1", "00:00:01"]
    EdlParser.extract_entry!(out).should == ["00:00:01.1", "00:00:01"]
    out.should == []
    
  end
  
end