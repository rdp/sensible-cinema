=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
=end
require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/edl_parser'

describe EdlParser do
  
  E = EdlParser
  
  it "should parse" do
    E.parse_string('"a" => "3"', nil).should ==  {"a"=>"3", "mutes"=>[], "blank_outs"=>[]}
  end
  
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
   E.parse_string(string, nil).should == expected
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
  
  it "should parse a real file" do
   E.parse_file(File.expand_path(__dir__) + "/../zamples/edit_decision_lists/dvds/bobs_big_plan.txt").should ==
      {"mutes"=>[["00:03.8", "01:03", "theme song is a bit raucous at times"], ["48:46", "49:08", "theme song again"], ["29:14", "30:46", "theme song again"]], "title"=>"Bob's Big Plan", "dvd_drive_label"=>"BOBS_BIG_PLAN", "source"=>"DVD", "dvd_title_track"=>1, "other notes"=>"could use more nit-picking of the song, as some parts seem all right in the end", "blank_outs"=>[]}
  end
  
  it "should be able to use personal preferences to decide which edits to make" do
   out = <<-EOL
      "mutes" => [
      "00:10", "00:15", "test category", "1",
      "00:20", "00:25", "test category", "2"
      ]
    EOL
    parsed = E.parse_string out, nil
    parsed["mutes"].length.should == 2 # has them both

    1.upto(2) do |n|
      parsed = E.parse_string(out, nil, [["test category", n.to_s]] )
      parsed["mutes"].length.should == 1 # has them both
    end
  end
  
end