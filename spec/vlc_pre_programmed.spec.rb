require File.dirname(__FILE__) + "/common"
require_relative '../lib/vlc_programmer'


describe 'VLC Programmer' do

  it "should be able to convert" do
  
    a = YAML.load_file "../zamples/scene_lists/dvds/happy_feet_dvd.yml"
    out = VLCProgrammer.convert_to_full_xspf(a)
    out.length.should_not == 0
    out.should include("playlist")
    out.scan(/vlc:id/).length.should be > 3
    
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

  it "should convert mutes and blanks apropo" do
    a = VLCProgrammer.convert_to_full_xspf({ "mutes"=>{105=>145, 2084=>2087, "46:33.5"=>2801, "01:33:21.0"=>"01:33:50.0"}, "blank_outs"=>{"55:35"=>"55:42.0"}})
    a.scan(/<vlc:id>/).length.should == 4*2+1 # should mute and play each time...
    a.scan(/start-time=0/).length.should == 1 # should start
    a.scan(/stop-time=1000000/).length.should == 1 # should complete the movie
  end

  it "should convert overlaps apropo"
  
end