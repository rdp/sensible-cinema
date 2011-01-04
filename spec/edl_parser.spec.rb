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
    "blank_outs"=>[["01:01:00", "01:02:00", "nudity", "..."], ["00:03:03.5", "00:03:04.5"]], 
    "missing_content"=>"this doesn't list some mild name calling", 
    "title"=>"Forever Strong", "source"=>"Hulu", "url"=>"http://www.byutv.org/watch/1790-100", 
    "whatever_else_you_want"=>"this is the old version of the film",
    "disk_unique_id"=>"19d131ae8dc40cdd70b57ab7e8c74f76"
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
    proc { EdlParser.extract_entry!(["a"])}.should raise_exception(SyntaxError) 
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
     {"title"=>"Bob's Big Plan", "dvd_title_track"=>1, "other notes"=>"could use more nit-picking of the song, as some parts seem all right in the end", "disk_unique_id"=>"259961ce38971cac3e28214ec4ec278b", "mutes"=>[["00:03.8", "01:03", "theme song is a bit raucous at times"], ["28:13.5", "29:40", "theme song again"], ["48:46", "49:08", "theme song again"]], "blank_outs"=>[]}
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
  
  it "should reject misformatted files" do
    proc {E.parse_string 'mutes=>["0:33", "0:34"]', 'filename'}.should raise_error(SyntaxError)
    proc {E.parse_string '"mutes"=>["0:33", "0:34"]', 'filename'}.should_not raise_error
  end
  
  it "should be able to optionally ignore settings" do
    E.parse_string('"mutes"=>["0:33", "0:34"]', 'filename', [], true)['mutes'].should == []
  end
  
  it "should sort exactly overlapping segments" do
    proc { go({"mutes"=>{105=>145}, "blank_outs"=>{105=>145}})}.should raise_error(SyntaxError)
    proc { go({"mutes"=>{105=>145}, "blank_outs"=>{110=>130}})}.should raise_error(SyntaxError)
    proc { go({"mutes"=>{105=>145}, "blank_outs"=>{110=>150}})}.should raise_error(SyntaxError)
  end
  
  it "should add to both ends" do
    go({"mutes"=>{105=>145}}, 1).should == [[105.0, 146.0, :mute]]
    go({"mutes"=>{105=>145}}, 1,1).should == [[104.0, 146.0, :mute]]
  end
  
  def go *args
    EdlParser.convert_incoming_to_split_sectors *args
  end
  
  it "should raise for end before beginning" do
    proc{ go({"mutes"=>{105=>104.9}})}.should raise_error(SyntaxError)
  end
  
  it "should allow for splits in its parseage" do
    go({ "mutes"=>{5=>6,105=>106}, "blank_outs" => {110 => 111} }, 0, 0, [103]).should == 
      [[2.0, 3.0, :mute], [5.0, 6.0, :mute], [7.0, 8.0, :blank]]
  end
  
  it "should take the greater of the end and beginning on combined splits and greater of the blank versus mute" do
    # so if I have a very long mute with a mute in the middle, it should turn into a very long mute
    proc{go({ "mutes"=>{5=>10, 6=>7}}, 0, 0, [1000])}.should raise_error(/overlap/i)
    go({ "mutes"=>{5=>10, 103=>107}}, 0, 0, [100])
    go({ "mutes"=>{5=>10, 103=>110}}, 0, 0, [100])
    go({ "mutes"=>{5=>10, 103=>111}}, 0, 0, [100])
    # now throw in blanks to the mix...

  end
  
end