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
    DriveInfo.get_dvd_drives_as_openstruct.length.should be > 0
    DriveInfo.get_dvd_drives_as_openstruct.each{|d|
      DriveInfo.md5sum_disk(d.Name + "/").length.should be > 0 if d.VolumeName
    }
  end
  
  it "should return a drive with most space" do
    DriveInfo.get_drive_with_most_space_with_slash[1..-1].should == ":\\"
  end

end
