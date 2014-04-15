
module SensibleSwing
  
  class MainWindow

    def setup_online_player_buttons
      require_relative '../online_movie_players.rb'
	  
	  add_text_line 'Online Player playback Options:'
      new_jbutton("Attempt to auto detect player and select url to use") do
        window = new_child_window
        window.setup_normal_buttons
      end
            
      new_jbutton("Open Website for editing/creating EDL's") do
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://inet2.org:8080/"
      end
	  add_open_documentation_button
    end
  end
end
