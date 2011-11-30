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
require_relative 'overlayer'

class VLCProgrammer

  def self.to_english s
    EdlParser.translate_time_to_human_readable s
  end
  

  def self.convert_to_full_xspf incoming, filename = nil, drive_with_slash = nil, dvd_title_track = nil, dvd_title_name = nil
  
    @drive = drive_with_slash || "e:\\"
    @filename_or_playlist_if_nil = filename
    @dvd_title_track = dvd_title_track || "1"
    @dvd_title_name = dvd_title_name
    combined = EdlParser.convert_incoming_to_split_sectors incoming
    
    out = get_header

    previous_end = 0
    idx = 0

    combined.each{|start, endy, type|
     # next unless start
      #next if endy <= start 
      real_start = start # NB that this fails with VLC or mplayer, because of i-frame difficulties (google mencoder start time)
      if previous_end != start
        # play 'uncut' up to next "questionable section"
        out += get_section("#{@dvd_title_name} : #{to_english previous_end} to #{to_english start} (clean)", previous_end, real_start, idx += 1)
      else
        # immediately let it do the next action
      end
      
      # now play through the muted section...
      if type == :mute
        out += get_section "#{@dvd_title_name} : #{to_english start}s to #{to_english endy}s muted", real_start, endy, idx += 1, true
      end
      previous_end = endy
    }

    # now play the rest of the movie...
    out += get_section to_english(previous_end) + " to end of film", previous_end, 1_000_000, idx += 1
    # and close the xml...
    out += get_footer idx
  
  end
  
  def self.get_header
    if @filename_or_playlist_if_nil == nil
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
      <playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\" xmlns:vlc=\"http://www.videolan.org/vlc/playlist/ns/0/\">
      <title>Playlist</title>
      <!--location>c:\\installs\\test.xspf</location--> 
      <trackList>"
    else
      ""
    end
  end
  
  def self.get_section title, start, stop, idx, no_audio = false
    loc = "dvdsimple://#{@drive}@#{@dvd_title_track}"
    if @filename_or_playlist_if_nil == nil
      "<track>
      <title>#{title}</title>
      <extension application=\"http://www.videolan.org/vlc/playlist/0\">
        <vlc:id>#{idx}</vlc:id>
        <vlc:option>start-time=#{start}</vlc:option>
        #{"<vlc:option>noaudio</vlc:option>" if no_audio}
        <vlc:option>stop-time=#{stop}</vlc:option>
      </extension>
      <location>#{loc}</location>
      </track>"
    else
      "vlc --qt-start-minimized #{loc} --start-time=#{start} --stop-time=#{stop} --sout=\"file/ps:#{@filename_or_playlist_if_nil}.ps.#{idx}\" #{"--no-sout-audio" if no_audio} vlc://quit\n" # + 
      #"vlc #{@filename_or_playlist_if_nil}.ps.#{idx}.tmp  --sout=file/ps:go.ps
    end
  end
  
  def self.get_footer idx
   if @filename_or_playlist_if_nil == nil
    "</trackList></playlist>"
   else
    filename = @filename_or_playlist_if_nil
    files = (1..idx).map{|n| "#{filename}.ps.#{n}"}
    # concat
    line = 'copy /b ' + files.join('+')
    line += " #{@filename_or_playlist_if_nil}.ps\n"    
    line += "@rem del " + files.join(' ') + "\n" # LODO!
    line += "echo Done--you may now watch file #{filename}.ps in VLC player"
   end
    
  end

end

