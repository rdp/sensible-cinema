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
require 'digest/md5'
require 'sane'
require 'ostruct'

class DriveInfo

 def self.md5sum_disk(dir)
  digest = Digest::MD5.new()
  files  = Dir[dir + "VIDEO_TS/*.IFO"]
  files.sort.each{|f| # sort tends to not do anything...
    digest << File.binread(f) 
  }
  raise 'drive might not yet have disc in it? ' + dir unless files.length > 0
  digest.hexdigest
 end

 def self.get_dvd_drives_as_openstruct
   disks = get_all_drives_as_ostructs
   disks.select{|d| d.Description =~ /CD-ROM/}.map{|d| d2 = OpenStruct.new; d2.VolumeName = d.VolumeName; d2.Name = d.Name; d2}
 end
  
 def self.get_drive_with_most_space_with_slash
  disks = get_all_drives_as_ostructs
  most_space = disks.sort_by{|d| d.FreeSpace}[-1]
  most_space.Name + "\\"
 end

 def self.get_all_drives_as_ostructs
  if OS.mac?
    require 'plist'
    a = Dir['/Volumes/*'].map{|dir|
     parsed = Plist.parse_xml(`diskutil info -plist "#{dir}"`)
     d2 = OpenStruct.new
     d2.VolumeName = parsed["VolumeName"]
     d2.Name = dir # DevNode?
     d2.FreeSpace = parsed["FreeSpace"].to_i
     d2.Description = parsed['Description'] # work ??
     d2
    }
    a
  else
    require 'ruby-wmi'
    disks = WMI::Win32_LogicalDisk.find(:all)
    disks.map{|d| d2 = OpenStruct.new; d2.Description = d.Description; d2.VolumeName = d.VolumeName; d2.Name = d.Name; d2.FreeSpace = d.FreeSpace.to_i; d2} 
  end
 end

end

