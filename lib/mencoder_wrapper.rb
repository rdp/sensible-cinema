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

require_relative 'edl_parser'

class MencoderWrapper
  class TimingError < StandardError
  end
  class << self
  
    def get_header this_drive, these_settings
      out = ''
      if File.exist?(@big_temp) && File.exist?(@big_temp + '.done')
        out = '@rem '
      end
      audio_codec = these_settings['audio_codec'] || 'lavc' # not copy...sniff...or you can't hear cars...
      video_opts = "-vf scale=720:480,harddup -ovc lavc -lavcopts vcodec=mpeg2video:vrc_buf_size=1835:vrc_maxrate=9800:vbitrate=5000:keyint=1:vstrict=0:acodec=ac3:abitrate=192:autoaspect -ofps 30000/1001"
      out + "mencoder dvdnav://#{@dvd_title_track} -of mpeg -mpegopts format=dvd:tsaf -alang en -nocache -sid 1000 -oac #{audio_codec} #{video_opts} -o #{@big_temp} -dvd-device #{this_drive} && echo done_grabbing > #{@big_temp}.done\n"
    end
    
    def calculate_final_filename to_here_final_file
      @big_temp = to_here_final_file + ".fulli_unedited.tmp.mpg"
    end
    
    # called from the UI...
    def get_bat_commands these_settings, this_drive, to_here_final_file, start_here = nil, end_here = nil, dvd_title_track = "1", delete_partials = false, require_deletion_entry = false
      combined = EdlParser.convert_incoming_to_split_sectors these_settings
      @dvd_title_track = dvd_title_track
      assert dvd_title_track
      if start_here || end_here
        raise 'need both' unless end_here && start_here
        start_here = EdlParser.translate_string_to_seconds(start_here)
        end_here   = EdlParser.translate_string_to_seconds(end_here)
        combined.select!{|start, endy, type| start > start_here && endy < end_here }
        raise TimingError.new("unable to find deletion entry between #{start_here} and #{end_here}") if require_deletion_entry && combined.length == 0
        # it's relative now, since we rip from not the beginning
        previous_end = start_here
      else
        previous_end = 0
      end
      calculate_final_filename to_here_final_file
      out = get_header this_drive, these_settings
      @idx = 0
      combined.each {|start, endy, type|
        if start > previous_end
          out += get_section previous_end, start, false, to_here_final_file
        end
        # type is either mute or :blank or :mute
        if type == :blank
         # do nothing... clip will be skipped
        else
          out += get_section start, endy, true, to_here_final_file
        end
        previous_end = endy
      }
      out += get_section previous_end, end_here || 1_000_000, false, to_here_final_file
      partials = (1..@idx).map{|n| "#{to_here_final_file}.#{n}.avi"}
      to_here_final_file = to_here_final_file + ".avi"
      if File.exist? to_here_final_file
        FileUtils.rm to_here_final_file # raises on deletion failure...which is what we want I think...hopefully.
      end
      out += "call mencoder #{partials.join(' ')} -o #{to_here_final_file} -ovc copy -oac copy\n"
      # LODO only do this if they want to watch it on their computer, with something other than smplayer, or want to make it smaller, as it takes *forever* longer to run...
      # or is ffdshow enough without this?
      out += "@rem old way... call mencoder -oac lavc -ovc lavc -of mpeg -mpegopts format=dvd:tsaf -vf scale=720:480,harddup -srate 48000 -af lavcresample=48000 -lavcopts vcodec=mpeg2video:vrc_buf_size=1835:vrc_maxrate=9800:vbitrate=5000:keyint=18:vstrict=0:acodec=ac3:abitrate=192:aspect=16/9 -ofps 30000/1001  #{partials.join(' ')} -o #{to_here_final_file}\n"
      
      delete_prefix = delete_partials ? "" : "@rem "

      out += "@rem del #{@big_temp}\n" # LODO no @rem
      out += "#{delete_prefix} del " + partials.join(' ') + "\n"
      out += "echo wrote (probably successfully) to #{to_here_final_file}"
      out
    end
    
    def get_section start, endy, should_mute, to_here_final_file    
      raise 'start == end' if start == endy # should never actually happen...
      # delete 0.001 as per wiki's suggestion.
      endy = endy - start - 0.001
      # very decreased volume is like muting :)
      # LODO can we copy more here? ntsc-dvd supposedly remuxes...
      codecs = should_mute ? "-vcodec copy -acodec ac3 -vol 0 " : "-vcodec copy -acodec copy " # LODO the ac3 must match the copy...hmm...
      partial_filename = to_here_final_file + '.' + (@idx += 1).to_s + '.avi'
      if File.exist? partial_filename
        FileUtils.rm partial_filename
      end
      "ffmpeg -i #{@big_temp} #{codecs} -ss #{start} -t #{endy} #{partial_filename}\n"
    end
  
  end

end
