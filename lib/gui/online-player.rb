
module SensibleSwing
  
  class MainWindow
  
    def setup_online_player_buttons
      require_relative '../online_movie_players.rb'	 
      add_text_line 'Online Player playback Options:'

      new_jbutton("Start edited playback") do
        @close_proc = go_online self
      end            

      new_jbutton("Stop edited playback") do
        @close_proc.call if @close_proc
      end            

      new_jbutton("Open Website for viewing/editing movie edit choices") do
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://cinemasoap.inet2.org"
      end	    
      @online_status_label = add_text_line "Player status:"
      @playing_well_label = add_text_line "Status: editor initializing..."
      # add_open_documentation_button # not pertinent enough yet...	  
      if ARGV.contain?('--go')
        button = new_jbutton("Auto start edited playback for testing") do
          path = File.dirname(__FILE__) + "/../../zamples/players/amazon/total_length_over_an_hour.txt"
          @close_proc = go_online self, false, "http://cinemasoap.inet2.org/view/abc?raw=1", path
        end
        button.click!
      end
    end

    def update_playing_well_status status
      @playing_well_label.set_text "Status:" + status
    end
    def update_online_player_status status
      @online_status_label.set_text "Player status:" + status
    end
  end
end
