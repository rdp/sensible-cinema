require File.dirname(__FILE__) + "/common"
require_relative '../lib/vlc_programmer'

describe 'VLC Programmer' do

  it "should be able to convert" do
  
    a = YAML.load_file "../zamples/scene_lists/dvds/happy_feet_dvd.yml"
    out = VLCProgrammer.convert_to_full_xspf(a)
    out.length.should != 0
    
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
  
end