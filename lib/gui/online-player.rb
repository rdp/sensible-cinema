
module SensibleSwing
  
  class MainWindow
    def setup_online_player_buttons
      require_relative '../online_movie_players.rb'	 
	  add_text_line 'Online Player playback Options:'
      new_jbutton("Attempt to auto detect player and select url to use") do
        go_online
      end
            
      new_jbutton("Open Website for viewing/editing movie edits") do
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://198.199.93.93/"
      end
	  # not pertinent enough...
	  # add_open_documentation_button
	  if ARGV.contain?('--go')
	    go_online
	  end
    end
  end
end
