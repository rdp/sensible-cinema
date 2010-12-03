require File.dirname(__FILE__) + "/common"
require_relative '../lib/mencoder_wrapper'

describe MencoderWrapper do

  before do
    FileUtils.rm 'to_here.fulli.tmp.avi.done' rescue nil
    FileUtils.rm 'to_here.fulli.tmp.avi' rescue nil
    @a = YAML.load_file "../zamples/edit_decision_lists/dvds/happy_feet.txt"
    @out = MencoderWrapper.get_bat_commands @a, "e:\\", 'to_here'
  end
  
  it "should be able to convert" do      
    @out.should_not be nil
    @out.should include("e:\\")
  end
  
  it "should have what looks like a working mencoder rip command" do
    @out.should match(/mencoder dvd.*keyint=1/)
  end
  
  it "should create a .done file after ripping" do
    @out.should include("&& echo got_file > to_here.fulli.tmp.avi.done")
  end
  
  def go
    @out = MencoderWrapper.get_bat_commands @a, "e:\\", 'to_here'
  end
    
  it "should not rip it again if the .done file exists and the original file exist" do
    go
    @out.should include(" -o to_here.fulli.tmp.avi")
    
    FileUtils.touch 'to_here.fulli.tmp.avi.done'
    go
    @out.should include(" -o to_here.fulli.tmp.avi")
    FileUtils.touch 'to_here.fulli.tmp.avi'
    go
    @out.should_not include(" -o to_here.fulli.tmp.avi")  
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
  
  it "should not overuse the avi extension" do
    @out.should_not include("avi.1.avi")
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
    1.upto(10) do |n|
      @out.should match(Regexp.new(/del.*#{n}/))
    end
    # should delete the right numbers, too, which starts at 1
    @out.should_not match(/del to_here.0.avi/)
    @out.should match(/del to_here.1.avi/)
  end
  
  it "should rm partial files before writing each one" do
    @out.should match(/del to_here.3.avi$/)
  end
  
  it "should echo that it is done, with the right filename" do
    @out.should include("echo wrote to to_here.avi")
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
    @out.should match(/-t 0.999/)
  end
  
  it "should not have doubled .avi.avi's" do
    setup  
    # lodo cleanup this ugliness
    @out.scan(/-i.*-t.*to_here.avi.1.avi/).length.should == 1
    @out.scan(/-i.*-t.*to_here.avi.2.avi/).length.should == 1
  end
  
  context 'pinpointing sections' do
    before do
     settings = {"mutes"=>{15=>20, 30 => 35}}
     @out = MencoderWrapper.get_bat_commands settings, "e:\\", 'to_here.avi', '00:14', '00:25'  
    end
    
    it "should always somewhat rip the whole thing" do
      @out.should_not match(/mencoder dvd.*endpos/)
    end
    
    it "should contain the included subsections" do
     @out.should_not include("-t 34.99")
     @out.should include("14.0")
     @out.should_not include("99999")
     @out.should include(" 0 ") # no start at 0 even
     @out.should include("-ss 14.0 -t 0.999")
     @out.should include("-ss 15.0 -t 4.999")
  end
  
  it "should raise if you focus down into nothing" do
    setup
    proc { MencoderWrapper.get_bat_commands @settings, "e:\\", 'to_here', '00:14', '00:15'}.should raise_error(/unable/)
  end
  
  it "should create a temp file" do
    
  end
  
end
  
end