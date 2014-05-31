
module SensibleSwing
  
  class MainWindow
  
    def start_new_run *args
      update_playing_well_status 'initializing...'
      @close_proc.call if @close_proc # reset in case they call start twice
      @close_proc, @overlay = go_online *args
    end
    
    def setup_online_player_buttons
      require_relative '../online_movie_players.rb'	 
      add_text_line 'Online Player playback Options:'

      test_video_url = "http://test.com/test"

      new_jbutton("Start edited playback") do
        # TODO movie_url = AutoWindowFinder.search_for_single_url_match
        movie_url = SimpleGuiCreator.get_user_input "please enter movie url, like http://www.amazon.com/gp/product/B004RFZODC", test_video_url
        # TODO players_root_dir = __DIR__ + "/../zamples/players"
        # player_description_path = AutoWindowFinder.search_for_player_and_url_match(players_root_dir)
        player_description_path = choose_file("     SELECT MOVIE PLAYER YOU INTEND ON USING", players_root_dir)
        raise unless player_description_path
        start_new_run self, false, movie_url, player_description_path
      end            

      new_jbutton("Stop edited playback tracker") do
        @close_proc.call if @close_proc
      end            

      new_jbutton("Open Website for viewing/editing all movie edit choice lists") do
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://cinemasoap.inet2.org/"
      end	    
      @online_status_label = add_text_line "Player status:"
      @playing_well_label = add_text_line "Status: hit start to being..."
      @playing_well_label2 = add_text_line ""
      # add_open_documentation_button # not pertinent enough yet...	  
      if ARGV.contain?('--advanced')
      
        path = File.dirname(__FILE__) + "/../../zamples/players/amazon/total_length_over_an_hour.txt"
        autostart = new_jbutton("Auto start edited playback for testing") do
          start_new_run self, false, test_video_url, path          
        end
        new_jbutton("Take screen snapshot of player descriptor") do
          start_new_run self, true, nil, path
        end
        new_jbutton("Reset current playerback time to 00:00s") do
          @overlay.timestamp_changed "0:0", 0
        end
        autostart.click!
      end
    end

    def update_playing_well_status status
      @playing_well_label.set_text "Status:" + status[0..50]
      if status.length > 50
        @playing_well_label2.set_text status[50..-1]
      else
        @playing_well_label2.set_text "" # reset it
      end
    end
    
    def update_online_player_status status
      @online_status_label.set_text "Player status:" + status
    end
  end
end
