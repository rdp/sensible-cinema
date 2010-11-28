require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/drive_info'

describe 'dvd_drive_info' do
  it 'should be able to get an md5sum from the dvd' do
    FileUtils.mkdir_p 'VIDEO_TS'
    Dir.chdir 'VIDEO_TS' do
      File.binwrite("VTS_01_0.IFO", "b")
      File.binwrite("VIDEO_TS.IFO", "a")
    end
    DriveInfo.md5sum_disk(".\\").should == Digest::MD5.hexdigest("ab")
  end
  
  it "should be able to do it for real drive" do
    DriveInfo.get_dvd_drives_as_win32ole.each{|d|
      DriveInfo.md5sum_disk(d.Name + "/").length.should be > 0 if d.VolumeName
    }
  end
  
  it "should return a drive with most space" do
    DriveInfo.get_drive_with_most_space_with_slash[1..-1].should == ":\\"
  end

end