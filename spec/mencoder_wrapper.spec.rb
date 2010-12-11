require File.dirname(__FILE__) + "/common"
require_relative '../lib/mencoder_wrapper'
require_relative '../lib/edl_parser'

# mpeg fulli one pass doesn't look "awful"
# mp4 fulli default looks way granular
# so could either attempt to re-encode at high cpu, possibly still lossy
# or do the frame accurate splitter. Prefer the latter.

describe MencoderWrapper do

  before do
    FileUtils.rm 'to_here.fulli.tmp.avi.done' rescue nil
    FileUtils.rm 'to_here.fulli.tmp.avi' rescue nil
    @a = EdlParser.parse_file "../zamples/edit_decision_lists/dvds/bobs_big_plan.txt"
    @out = MencoderWrapper.get_bat_commands @a, "e:\\", 'to_here'
  end
  
  it "should be able to convert" do      
    @out.should_not be nil
    @out.should include("e:\\")
  end
  
  it "should have what looks like a working mencoder grab command" do
    @out.should match(/mencoder dvdnav:/)
    @out.should match(/dvdnav.*lavcopt.*keyint=1/)
    use_mpg2_fulli = true
    if use_mpg2_fulli
      @out.should match(/dvdnav.*lavcopt.*mpeg2video/)
      @out.should match(/autoaspect/) # try to preserve aspect
    end
  end
  
  it "should avoid subtitles" do
    @out.should match(/-sid 1000/)
  end
  
  it "should default to english" do
    @out.should match(/-alang en/)
  end
  
  it "should create a .done file after ripping" do
    @out.should include("&& echo got_file > to_here.fulli.tmp.avi.done")
  end
  
  def go
    @out = MencoderWrapper.get_bat_commands @a, "e:\\", 'to_here'
  end
    
  it "should not grab it again if the .done file exists and the original file exist" do
    go
    @out.should include(" -o to_here.fulli.tmp.avi")
    
    FileUtils.touch 'to_here.fulli.tmp.avi.done'
    go
    @out.should include(" -o to_here.fulli.tmp.avi")
    FileUtils.touch 'to_here.fulli.tmp.avi'
    go
    @out.should match(/@rem.*-o to_here.fulli.tmp.avi/)  
  end
  
  it "should raise if the output file is held by some other process" do
    for file in ['to_here.avi', 'to_here.1.avi']
      open_handle = File.open(file, 'w')
      begin
        proc { go }.should raise_error(/Permission denied/)
      ensure
        open_handle.close
      end
    end
  end
  
  it "should use newline every line" do
    @out.should include("\n")
    @out.should_not match(/mencoder.*mencoder/)
    @out.should_not match(/del.*del/)
  end
  
  it "should use ffmpeg style start and stop times" do
    @out.should match(/ffmpeg.*-ss/)
    @out.should include(" -t ")
  end
  
  it "should have what looks like a working ffmpeg style split commands" do
    # ffmpeg -i from_here.avi   -vcodec copy -acodec copy -ss 1:00 -t 1:00 out.avi
    @out.should match(/ffmpeg -i to_here.*vcodec copy -acodec ac3 .*-ss .* -t /)
    @out.should_not match(/acodec copy.*vol 0/)
  end
  
  it "should accomodate for mutes the ffmpeg way" do
    # mutes by silencing...seems reasonable, based on the Family Law fella
    @out.should match(/ -vcodec copy -acodec ac3 -vol 0 /)
    @out.should_not match(/-vcodec copy.*-target ntsc-dvd/)
  end
  
  it "should use avi extension" do
    @out.should include(".avi ")
    @out.should_not include(".avi.1 ")
  end
  
  it "should concatenate (merge) them all together" do
    @out.should match(/mencoder.* -ovc copy -oac copy/)
    @out.should match(/mencoder to_here.1.avi/)
  end
  
  it "should create a large conglom file" do
    @out.should match(/mencoder.*-o to_here.avi -ovc copy -oac copy/)
  end
  
  it "should delete any large, grabbed tmp file" do
    @out.should match(/del.*tmp/)
  end
  
  it "should delete all partials" do
    1.upto(7) do |n|
      @out.should match(Regexp.new(/del.*#{n}/))
    end
    # should delete the right numbers, too, which starts at 1
    @out.should_not match(/del to_here.0.avi/)
    @out.should match(/del to_here.1.avi/)
  end
  
  it "should rm the files in the code, not the batch commands" do
    FileUtils.touch 'to_here.3.avi'
    File.exist?('to_here.3.avi').should be true
    out = MencoderWrapper.get_bat_commands @a, "e:\\", 'to_here'
    out.should_not match(/del to_here.3.avi$/)
    File.exist?('to_here.3.avi').should be false
  end
  
  it "should echo that it is done, and with the right filename" do
    @out.should include("echo wrote to to_here.avi")
  end
  
  it "should accept audio_code" do
    settings = {"audio_codec"=>"pcm"}
    out = MencoderWrapper.get_bat_commands settings, "e:\\", 'to_here.avi'
    out.should include("-oac pcm")
  end
  
  def setup
    @settings = {"mutes"=>{1=>2, 7=>12}, "blank_outs"=>{"2"=>"3"}}
    @out = MencoderWrapper.get_bat_commands @settings, "e:\\", 'to_here.avi'
  end
  
  it "should not insert an extra pause if a mute becomes a blank" do
    setup
    @out.should_not match(/-endpos 0.0/)
    File.write('out.bat', @out)
  end
  
  it "should not include blank sections" do
    setup
    @out.should_not include('-ss 2.0 -endpos 1.0')
    # and not be freaky by setting the end to nosound
    @out.should_not match(/-endpos \d{6}.*volume/)
  end
  
  it "should lop off a fraction of a second per segment, as per wiki instructions" do
    setup
    @out.should match(/0.999/)
  end
  
  it "should not have doubled .avi.avi's" do
    setup  
    # lodo cleanup this ugliness [.avi.1.avi]...
    @out.scan(/(ffmpeg|mencoder).*to_here.avi.1.avi/).length.should be >= 1
    @out.scan(/(ffmpeg|mencoder).*to_here.avi.2.avi/).length.should be >= 1
  end
  
  context 'pinpointing sections' do
    before do
     settings = {"mutes"=>{15=>20, 30 => 35}}
     @out = MencoderWrapper.get_bat_commands settings, "e:\\", 'to_here.avi', '00:14', '00:25'  
    end
    
    it "should always somewhat grab the whole thing, no endpos" do
      @out.should_not match(/mencoder dvd.*endpos/)
    end
    
    it "should contain the included subsections" do
     @out.should_not include("-t 34.99")
     @out.should include("14.0")
     @out.should_not include("99999")
     @out.should include(" 0 ") # no start at 0 even
     @out.should match(/-ss 14.0.*0.999/)
     @out.should match(/-ss 15.0.*4.999/)
  end
  
  it "should allow you to play something even if there's no edit list, just for examination sake" do
    setup
    proc { MencoderWrapper.get_bat_commands @settings, "e:\\", 'to_here', '00:14', '00:15'}.should_not raise_error(/unable/)
  end
  
end
  
end