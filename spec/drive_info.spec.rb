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
require_relative '../lib/drive_info'
require 'socket'

describe 'dvd_drive_info' do
  it 'should be able to get an md5sum from a dvd' do
    FileUtils.mkdir_p 'VIDEO_TS'
    Dir.chdir 'VIDEO_TS' do
      File.binwrite("VTS_01_0.IFO", "b")
      File.binwrite("VIDEO_TS.IFO", "a")
    end
    DriveInfo.md5sum_disk("./").should ==  
      if Socket.gethostname == "PACKR-B1C04F564"
        "b715cc2a|5e217436"
      elsif OS.windows? # blacky
        "ff83793c|dfaedb42"
      else # mac
        raise 'unknown here...' + DriveInfo.md5sum_disk("./")
      end
  end
  
  it "should be able to do it for real disc in the drive" do
    DriveInfo.get_dvd_drives_as_openstruct.length.should be > 0
    found_one = false
    DriveInfo.get_dvd_drives_as_openstruct.each{|d|
      if d.VolumeName # mounted ...
        DriveInfo.md5sum_disk(d.MountPoint).length.should be > 0
        found_one = true
        d.FreeSpace.should == 0
      end
    }
    found_one.should be true
  end

  it "should return a drive with most space" do
    space_drive = DriveInfo.get_drive_with_most_space_with_slash
    space_drive[1..-1].should == ":/" if OS.windows? # hope forward slash is ok...
    space_drive[0..0].should == "/" if !OS.windows?
    require 'fileutils'
    FileUtils.touch space_drive + 'touched_file'
    FileUtils.rm space_drive + 'touched_file'
  end

end
