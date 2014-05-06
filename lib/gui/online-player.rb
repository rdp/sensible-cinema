
module SensibleSwing
  
  class MainWindow
  
    def setup_online_player_buttons
      require_relative '../online_movie_players.rb'	 
	    add_text_line 'Online Player playback Options:'
      new_jbutton("Attempt to auto detect player and select url to use") do
        go_online self
      end            
      new_jbutton("Open Website for viewing/editing movie edits") do
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://198.199.93.93/"
      end	    
	    # add_open_documentation_button # not pertinent enough yet...	  
	    if ARGV.contain?('--go')
        button = new_jbutton("Auto go online") do
          go_online self, false, "http://198.199.93.93/view/abc?raw=1", "C:/dev/ruby/sensible-cinema/zamples/players/amazon/total_length_over_an_hour.txt"		
        end
		    button.click!
	    end
    end
    
  end
end
