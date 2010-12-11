if $0 == __FILE__
  require 'rubygems'
  require 'sane'
end

require_relative 'vlc_programmer'

class MencoderWrapper

  class << self
  
    def get_header this_drive, these_settings
      out = ''
      if File.exist?(@big_temp) && File.exist?(@big_temp + '.done')
        out = '@rem '
      end
      # video_opts = "-ovc lavc -lavcopts keyint=1" # seems reasonable quality somehow...
      # equivalent of ffmpeg's -target ntsc-dvd...I think...except that aspect thing terrifies me...
      audio_codec = these_settings['audio_codec'] || 'copy'
      video_opts = "-ovc lavc -lavcopts vcodec=mpeg2video:vrc_buf_size=1835:vrc_maxrate=9800:vbitrate=5000:keyint=1:vstrict=0:acodec=ac3:abitrate=192:autoaspect -ofps 30000/1001"
      out + "call mencoder dvdnav://#{@dvd_title_track} -alang en -nocache -sid 1000 -oac #{audio_codec} #{video_opts} -ovc lavc -o #{@big_temp} -dvd-device #{this_drive} && echo got_file > #{@big_temp}.done\n"
    end
    
    def get_bat_commands these_settings, this_drive, to_here_final_file, start_here = nil, end_here = nil, dvd_title_track = "1"
      combined = VLCProgrammer.convert_incoming_to_split_sectors these_settings
      @dvd_title_track = dvd_title_track
      if start_here || end_here
        raise 'need both' unless end_here && start_here
        start_here = OverLayer.translate_string_to_seconds(start_here)
        end_here   = OverLayer.translate_string_to_seconds(end_here)
        combined.select!{|start, endy, type| start > start_here && endy < end_here }
        # it's relative now, since we rip from not the beginning
        previous_end = start_here
      else
        previous_end = 0
      end
      @big_temp = to_here_final_file + ".fulli.tmp.avi"
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
        FileUtils.rm to_here_final_file # raises on failure...which is what we want I think
      end
      # ridiculous
      out += "call mencoder #{partials.join(' ')} -o #{to_here_final_file} -ovc copy -oac copy\n"
      # LODO only do this if they want to watch it on their computer, with something other than smplayer, or want to make it smaller, as it takes *forever* longer
      # LODO the "insta play" mode, or the "faster rip" mode (related...)
      out += "@rem call mencoder -oac lavc -ovc lavc -of mpeg -mpegopts format=dvd:tsaf -vf scale=720:480,harddup -srate 48000 -af lavcresample=48000 -lavcopts vcodec=mpeg2video:vrc_buf_size=1835:vrc_maxrate=9800:vbitrate=5000:keyint=18:vstrict=0:acodec=ac3:abitrate=192:aspect=16/9 -ofps 30000/1001  #{partials.join(' ')} -o #{to_here_final_file}\n"

      out += "@rem del #{@big_temp}\n" # LODO no @rem
      out += "del " + partials.join(' ') + "\n"# LODO no @rem
      out += "echo wrote to #{to_here_final_file}"
      out
    end
    
    def get_section start, endy, should_mute, to_here_final_file    
      raise if start == endy # should never actually happen...
      # delete 0.001 as per wiki's suggestion.
      endy = endy - start - 0.001
      # very decreased volume is like muting :)
      # LODO can we copy more here? ntsc-dvd supposedly remuxes...
      codecs = should_mute ? "-vcodec copy -acodec ac3 -vol 0 " : "-vcodec copy -acodec copy " # LODO the ac3 must match the copy...hmm...
      partial_filename = to_here_final_file + '.' + (@idx += 1).to_s + '.avi'
      if File.exist? partial_filename
        FileUtils.rm partial_filename
      end
      "call ffmpeg -i #{@big_temp} #{codecs} -ss #{start} -t #{endy} #{partial_filename}\n"
    end
  
  end

end

if $0 == __FILE__
  require 'rubygems'
  require 'sane'
  puts 'syntax: yaml_file_name d:\ output (00:15 00:25) (--run)'
  a = YAML.load_file ARGV.shift
  drive = ARGV.shift
  raise 'wrong drive' unless File.exist?(drive + "AUDIO_TS")
  execute = ARGV.delete('--run')
  commands = MencoderWrapper.get_bat_commands(a, drive, *ARGV)
  if ARGV.length > 2
    write_to = 'range.bat'
  else
    write_to = 'all.bat'
  end
  File.write(write_to, commands)
  print 'wrote ' + write_to
  system(write_to) if execute
end