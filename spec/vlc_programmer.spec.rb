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
require File.dirname(__FILE__) + "/common"
require_relative '../lib/vlc_programmer'


describe 'VLC Programmer' do

  it "should be able to convert" do  
    a = YAML.load_file "../zamples/edit_decision_lists/dvds/happy_feet.txt"
    out = VLCProgrammer.convert_to_full_xspf(a)
    out.length.should_not == 0
    out.should include("<title>Playlist</title>")
    out.scan(/vlc:id/).length.should be > 0
  end

  before do
   @a = VLCProgrammer.convert_to_full_xspf({ "mutes"=>{105=>145, "46:33.5"=>2801} } )
  end

  it "should convert mutes and blanks apropo" do
    @a.scan(/<vlc:id>/).length.should == 5 # should mute and play each time...
    @a.scan(/start-time=0/).length.should == 1 # should start
    @a.scan(/stop-time=1000000/).length.should == 1 # should have one to "finish" the DVD
    @a.scan(/<\/playlist/).length.should == 1
  end

  it "should have pretty english titles" do
    @a.scan(/ to /).length.should == 2*2+1
    @a.scan(/clean/).length.should be > 0
    @a.scan(/2:25/).length.should == 2
    @a.scan(/noaudio/).length.should be > 0
  end

  it "should handle blank outs, too" do
    # shouldn't have as many in the case of blanks...
    a = VLCProgrammer.convert_to_full_xspf({ "blank_outs" => {63=>64} } )
    a.should include("63")
    a.should include("64")
    a.scan(/ to /).length.should == 2
  end

  it "should handle combined blank and audio well" do
    # currently it handles blanks as skips...
    # possibly someday we should allow for blanks as...blanks?  blank-time somehow, with the right audio?
    # for now, skip for blanks, mute for mutes...

    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {5=> 7}, "blank_outs" => {6=>7} } )
    # should mute 5-6, skip 6-7
    a.scan(/noaudio/).length.should == 1
    a.scan(/ to /).length.should == 3 # 0->5, 5->6, 7-> end
    a.scan(/=5/).length.should == 2
    a.scan(/=6/).length.should == 1
    a.scan(/=7/).length.should == 1
    
    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {6=> 7}, "blank_outs" => {5=>7} } )
    a.scan(/=6/).length.should == 0
    a.scan(/noaudio/).length.should == 0
    a.scan(/ to /).length.should == 2 # 0->5, 7-> end

    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {6=> 7}, "blank_outs" => {5=>6.5} } )
    # should skip 5 => 6.5, mute 6.5 => 7

    a.scan(/noaudio/).length.should == 1
    a.scan(/ to /).length.should == 3 # 0->5, 6.5 => 7, 7 -> end
    a.scan(/=5/).length.should == 1
    a.scan(/=6.5/).length.should == 1
    a.scan(/=7/).length.should == 2


    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {6=> 7}, "blank_outs" => {6=>7} } )
    # should ignore mutes here
    a.scan(/ to /).length.should == 2 # 0->6, 7 -> end

    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {6.5=> 7}, "blank_outs" => {6=>7} } )
    # should ignore mutes here
    a.scan(/ to /).length.should == 2 # 0->6, 7 -> end

  end

  it "should not try to save it to a file from within the xml" do
    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {5=>10} } )
    a.scan(/sout=.*/).length.should  == 0
    bat_file = VLCProgrammer.convert_to_full_xspf({ "mutes" => {5=>10} }, 'go' )
    bat_file.scan(/sout=.*/).length.should be > 0
    bat_file.scan(/playlist/i).length.should == 0
    bat_file.scan(/--no-sout-audio/).length.should == 1
    bat_file.scan(/\n/).length.should be > 2
    bat_file.scan(/go.ps.1\+go.ps.2/).length.should == 1
    bat_file.scan(/go.ps.4/).length.should == 0
    bat_file.scan(/--start-time/).length.should == 3
    bat_file.scan(/quit/).length.should == 3
    bat_file.scan(/copy \/b/).length.should == 1
    bat_file.scan(/del go.ps.1/).length.should == 1
    bat_file.scan(/echo/).length.should == 1
    # should not have extra popups...
    bat_file.scan(/--qt-start-minimized/i).length.should == 3
    File.write('mute5-10.bat', bat_file)
    puts 'run it like $ mute5-10.bat'
  end
  
  it "should produce a file playable by windows media player"
  
end