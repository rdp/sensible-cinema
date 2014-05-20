
module SensibleSwing
  
  class MainWindow
  
    def setup_online_player_buttons
      require_relative '../online_movie_players.rb'	 
	    add_text_line 'Online Player playback Options:'
      new_jbutton("Attempt to auto detect player and select url to use") do
        go_online self
      end            
      new_jbutton("Open Website for viewing/editing movie edits") do
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://cinemasoap.inet2.org"
      end	    
	    # add_open_documentation_button # not pertinent enough yet...	  
	    if ARGV.contain?('--go')
        button = new_jbutton("Auto go online") do
          path = File.dirname(__FILE__) + "/../../zamples/players/amazon/total_length_over_an_hour.txt"
          go_online self, false, "http://cinemasoap.inet2.org/view/abc?raw=1", path
        end
		    button.click!
	    end
    end
    
  end
end
