require File.dirname(__FILE__) + "/common"
require_relative '../lib/vlc_programmer'


describe 'VLC Programmer' do

  it "should be able to convert" do
  
    a = YAML.load_file "../zamples/scene_lists/dvds/happy_feet_dvd.yml"
    out = VLCProgrammer.convert_to_full_xspf(a)
    out.length.should_not == 0
    out.should include("playlist")
    out.scan(/vlc:id/).length.should be > 0
    
=begin
<?xml version=”1.0″ encoding=”UTF-8″?>
<playlist version=”1″ xmlns=”http://xspf.org/ns/0/” xmlns:vlc=”http://www.videolan.org/vlc/playlist/ns/0/”>
<title>Playlist</title>
<location>c:\installs\test.xspf</location>
<trackList>
<track>
<title>Track 1</title>
…
<extension application=”http://www.videolan.org/vlc/playlist/0″>
<vlc:id>0</vlc:id>
<vlc:option>start-time=42</vlc:option>
<vlc:option>stop-time=45</vlc:option>
</extension>
<location>dvd://e:\@1</location>
</track>
<track>
<title>Track 2</title>
=end        
    
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
    @a.scan(/no-audio/).length.should be > 0
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
    a.scan(/no-audio/).length.should == 1
    a.scan(/ to /).length.should == 3 # 0->5, 5->6, 7-> end
    a.scan(/=5/).length.should == 2
    a.scan(/=6/).length.should == 1
    a.scan(/=7/).length.should == 1
    
    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {6=> 7}, "blank_outs" => {5=>7} } )
    a.scan(/=6/).length.should == 0
    a.scan(/no-audio/).length.should == 0
    a.scan(/ to /).length.should == 2 # 0->5, 7-> end

    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {6=> 7}, "blank_outs" => {5=>6.5} } )
    # should skip 5 => 6.5, mute 6.5 => 7

    a.scan(/no-audio/).length.should == 1
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
    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {6=> 7} } )
    a.scan(/sout=.*/).length.should  == 0
  end

  it "should have a workable usable VLC file" do
    a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {5=> 10} } )
    a.scan(/vlc:\/\/quit/).length.should == 1
    File.write('mute5-10.xspf', a)
    puts 'run it like $ vlc mute5-10.xspf --sout=file/ps:go.mpg --sout-file-append vlc://quit'
  end
  
end