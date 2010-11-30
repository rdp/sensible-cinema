class MencoderWrapper

class << self

  # it should 
  def get_bat_commands these_mutes, this_drive, to_here_final_file
    "mencoder dvd:// -oac copy -lavcopts keyint=1 -ovc lavc -o #{to_here_final_file}.tmp -dvd-device #{this_drive}"
    
  end

end

end