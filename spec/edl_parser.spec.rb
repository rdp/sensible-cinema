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

# MplayerEdl spec also exercises this pretty good...

describe EdlParser do
  
  E = EdlParser
  
  it "should parse" do
    E.parse_string('"a" => "3"', nil).should ==  {"a"=>"3", "mutes"=>[], "blank_outs"=>[]}
  end
  
  it "should get mutes and blank_outs" do
    string = <<-EOL
      "mutes" => [
        "00:00:01", "00:00:02",
        "00:00:01", "00:00:02", "profanity", "dang",
      ],
      "blank_outs" => [
        "01:01:00", "01:02:00", "nudity", "...",
      ],
      "missing_content" => "some stuff"
    EOL
   expected = 
   {
    "mutes"=>[["00:00:01", "00:00:02"], 
    ["00:00:01", "00:00:02", "profanity", "dang"]], 
    "blank_outs"=>[["01:01:00", "01:02:00", "nudity", "..."], ], 
    "missing_content"=>"some stuff", 
   }
   E.parse_string(string, nil).should == expected
  end
  
  it "should disallow full digits only" do
    proc {E.parse_string(%!"mutes" => ["1234", "1235", "profanity", "yo"]!, nil) }.should raise_exception SyntaxError    
    proc {E.parse_string(%!"mutes" => ["0.0", "1.1", "profanity", "yo"]!, nil) }.should_not raise_exception    
    proc {E.parse_string(%!"mutes" => ["0.0", "1.1", "profanity", "yo", "1234", "1235", "bad entry"]!, nil) }.should raise_exception SyntaxError    
  end
  
  it "should extract digits well" do
    out = ["00:00:01.1", "00:00:01"]
    EdlParser.extract_entry!(out).should == ["00:00:01.1", "00:00:01"]
    out.should == []    
  end
  
  it "should extract digits plus 'stuff' well" do
    out = ["1:01", "1:01", "a", "2:01", " 2:02", "b"]
    EdlParser.extract_entry!(out).should == ["1:01", "1:01", "a"]
    EdlParser.extract_entry!(out).should == ["2:01", " 2:02", "b"]
  end
  
  it "should parse with spaces ok" do
    EdlParser.translate_string_to_seconds(" 2:02").should == 60*2+2
  end
  
  it "should raise if the first two aren't digits, which is unexpected" do
    proc { EdlParser.extract_entry!(["a"])}.should raise_exception(SyntaxError) 
  end
  
  it "should detect timestamps well" do
    t = EdlParser::TimeStamp
    for ts in ["2:01", "1:01.5", "00:00:00.5","00:00:00", "1:23", "01:23"]
      raise ts unless t =~ ts
    end
   "5".should_not match(t)
   "category".should_not match(t)
  end
  
  it "should parse a real file" do
   E.parse_file(File.expand_path(__DIR__) + "/../zamples/edit_decision_lists/dvds/bobs_big_plan.txt").should ==
     {"title"=>"Bob's Big Plan", "dvd_title_track"=>1, "other notes"=>"could use more nit-picking of the song, as some parts seem all right in the end", "disk_unique_id"=>"12e77a76|b6e48ce8",  "volume_name"=>"BOBS_BIG_PLAN","mutes"=>[["00:03.8", "01:03", "theme song is a bit raucous at times"], ["28:13.5", "29:40", "theme song again"], ["48:46", "49:08", "theme song again"]], "blank_outs"=>[]}
  end
  
  it "should be able to use personal preferences to decide which edits to make" do
   out = <<-EOL
      "mutes" => [
      "00:10", "00:15", "test category", "cat1",
      "00:20", "00:25", "test category", "cat2",
      "00:30", "00:35", "test category", "cat3"
      ]
    EOL
    parsed = E.parse_string out, nil
    parsed["mutes"].length.should == 3 # has all of them

    1.upto(2) do |n|
      parsed = E.parse_string(out, nil, [["test category", "cat" + n.to_s]] )
      parsed["mutes"].length.should == 2 # excludes one
    end
    parsed = E.parse_string(out, nil, [["test category", "cat1"], ["test category", "cat2"]] )
    parsed["mutes"].length.should == 1 # excludes two

    # now with...just saying "this entire category is fine"
    parsed = E.parse_string(out, nil, [["test category"]])
    parsed["mutes"].length.should == 0

    pending do
      # now with...just saying "levels below this are ok"
      parsed = E.parse_string(out, nil, [["test category", 2]])
      parsed["mutes"].length.should == 2
    end
  end
  
  it "should parse mplayer_dvd_splits as strings" do
    E.parse_string('"mplayer_dvd_splits" => []', 'fakename')['mplayer_dvd_splits'].should == []
    E.parse_string('"mplayer_dvd_splits" => ["123.5","124.5"]', 'fakename')['mplayer_dvd_splits'].should == ["123.5","124.5"]
  end
  
  it "should reject misformatted files" do
    proc {E.parse_string 'mutes=>["0:33", "0:34"]', 'filename'}.should raise_error(SyntaxError)
    proc {E.parse_string '"mutes"=>["0:33", "0:34"]', 'filename'}.should_not raise_error
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
      [[1.0, 4.0, :mute], [5.0, 6.0, :mute], [6.0, 9.0, :blank]]
  end
  
  it "should raise on poor overlap" do
    proc{go({ "mutes"=>{5=>10, 6=>7}}, 0, 0, [1000])}.should raise_error(/overlap/i)
  end
  
  # I put down it at 10:00 it's at 10:00.5
  # so...postludingers should be...too early now?
  # change when complaints come in :P
  it "should take the greater of the end and beginning on combined splits and greater of the blank versus mute" do
    # so if I have a very long mute with a mute in the middle, it should turn into a very long mute
    go({ "mutes"=>{5=>10, 103=>107}}, 0, 0, [100]).should == [[2.0, 10.0, :mute]]
    go({ "mutes"=>{5=>10, 103=>110}}, 0, 0, [100]).should == [[2.0, 11.0, :mute]]
    go({ "mutes"=>{5=>15, 103=>110}}, 0, 0, [100]).should == [[2.0, 15.0, :mute]]
    go({ "mutes"=>{5=>10, 103=>111}}, 0, 0, [100]).should == [[2.0, 12.0, :mute]]
    # now throw in blanks to the mix...
    go({ "mutes"=>{5=>10}, "blank_outs" => {103=>110}}, 0, 0, [100]).should == [[2.0, 11.0, :blank]]
    go({ "blank_outs"=>{5=>10}, "mutes" => {103=>110}}, 0, 0, [100]).should == [[2.0, 11.0, :blank]]
  end
  
  it "should accomodate well for multiple mplayer_dvd_splits, and one edge case [zero]" do
    go({ "mutes"=>{5=>10, 75 => 76, 101 => 102}}, 0, 0, [50, 50]).should == 
      [[0.0, 4.0, :mute], [5.0, 10.0, :mute], [24.0, 27.0, :mute]]
  end
  
  it "should handle edge cases, like where an entry overlaps the divider, or the added stuff causes it to"
  
  def translate x
    EdlParser.translate_string_to_seconds x
  end
  
  def english y
    EdlParser.translate_time_to_human_readable y
  end
  
  it "should translate strings to ints well" do
    translate("00.09").should == 0.09
    translate("1.1").should == 1.1
    translate("01").should == 1
    translate("1:01").should == 61
    translate("1:01:01.1").should == 60*61+1.1
    translate("1:01:01").should == 60*61+1
  end
  
  it "should translate subtitle type timestamps" do
    translate("00:00:34,451").should == 34.451
  end
  
  it "should disallow malformed" do
    proc {translate("00:00:34,45a")}.should raise_exception
  end
  
  it "should translate ints to english timestamps well" do
    english(60).should == "01:00.00"
    english(60.1).should == "01:00.10"
    english(3600).should == "1:00:00.00"
    english(3599).should == "59:59.00"
    english(3660).should == "1:01:00.00"
    english(3660 + 0.1).should == "1:01:00.10"
  end
  
  it "should auto-select a (nested) EDL if it matches a DVD's id" do
    FileUtils.mkdir_p 'files/edls/a/b/c'
    File.write('files/edls/a/b/c/yo.txt', %!"disk_unique_id" => "deadbeef|8b27d001"!)
    EdlParser.single_edit_list_matches_dvd("deadbeef|8b27d001").should_not be nil
  end
  
  it "should not auto-select if you pass it nil" do
    File.write('files/edls/yo', %!"disk_unique_id" => "deadbeef|8b27d001"!)
    EdlParser.single_edit_list_matches_dvd(nil).should be nil
  end

  EdlParser::EDL_DIR.gsub!(/^.*$/, 'files/edls')

  it "should not select a file if poorly formed" do
    EdlParser.stub!(:parse_file) {
      eval("a----")
    }
    EdlParser.single_edit_list_matches_dvd('fake md5') # doesn't choke
  end
  
  it "should return false if two EDL's match a DVD title" do
      begin
        EdlParser.single_edit_list_matches_dvd("abcdef1234").should be nil
        File.binwrite('files/edls/a.txt', "\"disk_unique_id\" => \"abcdef1234\"")
        EdlParser.single_edit_list_matches_dvd("abcdef1234").should == "files/edls/a.txt"
        File.binwrite('files/edls//b.txt', "\"disk_unique_id\" => \"abcdef1234\"")
        EdlParser.single_edit_list_matches_dvd("abcdef1234").should be nil
      ensure
        FileUtils.rm_rf 'files/edls/a.txt'
        FileUtils.rm_rf 'files/edls/b.txt'
      end
    end


   it "should merge two files if one specifies another" do
     begin
       File.binwrite('files/edls/a.txt', %!"take_from_relative_file" => "b.txt"!)
       File.binwrite('files/edls/b.txt', %!!) # empty to start out with ...nothing up my sleeve...
       EdlParser.parse_file('files/edls/a.txt').should == {"take_from_relative_file" => "b.txt", "mutes" => [], "blank_outs" => []}
       File.binwrite('files/edls/b.txt', %!"blank_outs" => ["00:01", "00:03", "violence"], "yo" => "33"!)
       EdlParser.parse_file('files/edls/a.txt').should == {"take_from_relative_file" => "b.txt", "mutes" => [], "blank_outs" => [["00:01", "00:03", "violence"]], "yo" => "33"}
     ensure
       FileUtils.rm_rf 'files/edls/a.txt'
       FileUtils.rm_rf 'files/edls/b.txt'
     end
   end
  
    before do
      FileUtils.mkdir_p 'files/edls'
    end
    after do
      FileUtils.rm_rf 'files/edls'
    end

   it "should download from imdb if specified and merge" do
     File.binwrite('files/edls/a.txt', %!"imdb_id" => "tt1727587"!)
     EdlParser.parse_file('files/edls/a.txt').should == {"blank_outs" => [["0:00:56", "0:00:57"], ["0:01:05", "0:01:14.50"]], "mutes" => [], "imdb_id" => "tt1727587"}
   end
  
  it "should be able to convert to DVDNAV time" do
    
    #"dvd_title_track_start_offset" => "0.06",
    #"dvd_nav_packet_offset" => [0.866667, 0.944217],
    
    start = [[[1.0, 2.0], :blank], [3.0, 4.0], :mute]
    endy = EdlParser.convert_to_dvd_nav_times start, 'dvd_start_offset', 0.06, [0.866667, 0.944217], 29.97
    p endy
  end
  
end
