require_relative 'vlc_programmer'

class MencoderWrapper

  class << self
  
    # it should 
    def get_bat_commands these_mutes, this_drive, to_here_final_file
      combined = VLCProgrammer.convert_incoming_to_split_sectors these_mutes
      "mencoder dvd:// -oac copy -lavcopts keyint=1 -ovc lavc -o #{to_here_final_file}.tmp -dvd-device #{this_drive}"      
      
    end
  
  end

end