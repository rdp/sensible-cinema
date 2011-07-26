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
require 'rubygems'
require 'sane'
require 'ostruct'
require 'benchmark'
class DriveInfo

 def self.md5sum_disk(dir)
   if OS.mac?
     command = "#{__DIR__}/../vendor/mac_dvdid/bin/dvdid #{dir}"
   else
     command = "#{__DIR__}/../vendor/dvdid.exe #{dir}"
   end
   output = `#{command}` # can take like 2.2s
   raise 'dvdid command failed?' + command unless $?.exitstatus == 0
   output.strip
 end

 def self.get_dvd_drives_as_openstruct
   disks = get_all_drives_as_ostructs
   disks.select{|d| d.Description =~ /CD-ROM/ && File.exist?(d.Name + "/VIDEO_TS")}
 end
  
 def self.get_drive_with_most_space_with_slash
  disks = get_all_drives_as_ostructs
  most_space = disks.sort_by{|d| d.FreeSpace}[-1]
  most_space.MountPoint + "/"
 end

 def self.get_all_drives_as_ostructs # not just DVD drives...
  if OS.mac?
    require 'plist'
    Dir['/Volumes/*'].map{|dir|
     parsed = Plist.parse_xml(`diskutil info -plist "#{dir}"`)
     d2 = OpenStruct.new
     d2.VolumeName = parsed["VolumeName"]
     d2.Name = dir # DevNode?
     d2.FreeSpace = parsed["FreeSpace"].to_i
     d2.Description = parsed['OpticalDeviceType']
     d2.MountPoint = parsed['MountPoint']
     if d2.MountPoint == '/'
       d2.MountPoint = File.expand_path '~' # better ? I guess?
     end
     d2
    }
  else
    require 'ruby-wmi'
    disks = WMI::Win32_LogicalDisk.find(:all)
    disks.map{|d| d2 = OpenStruct.new
      d2.Description = d.Description
      d2.VolumeName = d.VolumeName
      d2.Name = d.Name
      d2.FreeSpace = d.FreeSpace.to_i
      d2.MountPoint = d.Name[0..2] # needed...
      d2
    } 
  end
 end

end

if $0 == __FILE__
  p DriveInfo.get_dvd_drives_as_openstruct
end
