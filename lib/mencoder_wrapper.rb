require_relative 'vlc_programmer'

class MencoderWrapper

  class << self
  
    # it should 
    def get_bat_commands these_mutes, this_drive, to_here_final_file
      combined = VLCProgrammer.convert_incoming_to_split_sectors these_mutes
      out = "mencoder dvd:// -oac copy -lavcopts keyint=1 -ovc lavc -o #{to_here_final_file}.tmp -dvd-device #{this_drive}"      
      
      previous_end = 0
      combined.each_with_index{|(start, endy, type), idx|
        # TODO test no intermediate section if blank follows blank et al
        out += get_section previous_end, start, idx, false, to_here_final_file
        out += get_section start, endy, type == :mute, idx, to_here_final_file
        previous_end = endy
      }
      out += get_section previous_end, 1_000_000, false, combined.length, to_here_final_file
      # TODO join them all together
      out += "mencoder #{to_here_final_file}.tmp.* -o #{to_here_final_file}\n"
      out += "@rem del #{to_here_final_file}.tmp"
      # TODO delete olds...
      out
    end
    
    def get_section start, endy, idx, should_mute, to_here_final_file
      # type is either mute or :blank or :mute
      # TODO should mute
      "mencoder #{to_here_final_file}.tmp -ss #{start} -endpos #{endy - start} -o #{to_here_final_file}.tmp.#{idx} -ovc copy -avc copy\n"
    end
  
  end

end