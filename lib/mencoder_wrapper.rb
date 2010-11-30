require_relative 'vlc_programmer'

class MencoderWrapper

  class << self
  
    def get_bat_commands these_mutes, this_drive, to_here_final_file
      combined = VLCProgrammer.convert_incoming_to_split_sectors these_mutes
      @big_temp = to_here_final_file + ".fulli.tmp.avi"
      out = "call mencoder dvd:// -oac copy -lavcopts keyint=1 -ovc lavc -o #{@big_temp} -dvd-device #{this_drive} \n"
      previous_end = 0
      @idx = 0
      combined.each {|start, endy, type|
        if start > previous_end
          out += get_section previous_end, start, false, to_here_final_file
        end
        # type is either mute or :blank or :mute
        if type == :blank
         # do nothing... clip will be avoided
        else
          out += get_section start, endy, true, to_here_final_file
        end
        previous_end = endy
      }
      out += get_section previous_end, 1_000_000, false, to_here_final_file
      partials = (1..@idx).map{|n| "#{to_here_final_file}.avi.#{n}"}
      
      out += "del #{to_here_final_file}\n"
      #out += "copy /b #{partials.join('+')} #{to_here_final_file}\n"
      out += "mencoder #{partials.join(' ')} -o #{to_here_final_file} -ovc copy -oac copy\n"
      out += "@rem del #{@big_temp}\n" # LODO
      
      out += "@rem del " + partials.join(' ') + "\n"# LODO

      out
    end
    
    def get_section start, endy, should_mute, to_here_final_file    
      raise if start == endy # should never be able to happen...
      # delete 0.001 as per wiki's suggestion.
      endy = endy - 0.001
      # very decreased volume is like muting :)
      sound_command = should_mute ? "-af volume=-200 -oac lavc" : "-oac lavc"  # LODO -oac copy ?
      "call mencoder #{@big_temp} -ss #{start} -endpos #{endy} -o #{to_here_final_file}.avi.#{@idx += 1} -ovc copy #{sound_command}\n"
    end
  
  end

end