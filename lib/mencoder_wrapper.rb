require_relative 'vlc_programmer'

class MencoderWrapper

  class << self
  
    def get_bat_commands these_mutes, this_drive, to_here_final_file
      combined = VLCProgrammer.convert_incoming_to_split_sectors these_mutes
      @big_temp = to_here_final_file + ".fulli.tmp.avi"
      out = "mencoder dvd:// -oac copy -lavcopts keyint=1 -ovc lavc -o #{@big_temp} -dvd-device #{this_drive}"      
      previous_end = 0
      combined.each_with_index{|(start, endy, type), idx|
        if start > previous_end
          out += get_section previous_end, start, idx, false, to_here_final_file
        end
        # type is either mute or :blank or :mute
        out += get_section start, endy, type == :mute, idx, to_here_final_file
        previous_end = endy
      }
      out += get_section previous_end, 1_000_000, false, combined.length, to_here_final_file      
      out += "mencoder #{to_here_final_file}.avi.* -o #{to_here_final_file}\n"
      out += "@rem del #{@big_temp}\n" # LODO
      partials = (0..(combined.length)).map{|n| "#{to_here_final_file}.avi.#{n}"}
      out += "@rem del " + partials.join(' ') # LODO
      out
    end
    
    def get_section start, endy, idx, should_mute, to_here_final_file
      raise if start == endy # should never happen...
      "mencoder #{@big_temp} -ss #{start} -endpos #{endy - start} -o #{to_here_final_file}.avi.#{idx} -ovc copy #{should_mute ? " -nosound" : "-oac copy"}\n"
    end
  
  end

end