class MencoderWrapper

class << self
  def get_bat_commands these_mutes, this_drive
    "mencoder dvd:// -oac copy -lavcopts keyint=1 -ovc lavc -o out23 -dvd-device #{this_drive}"
  end
end
end