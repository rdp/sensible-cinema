require 'pathname'

module SensibleSwing
  
  class MainWindow
    #def initialize
    #  @close_proc = nil # avoid warning
    #end
  
    def start_new_run parent_window, just_screen_snapshot, movie_url, amazon_episode_number, player_description_path
      update_playing_well_status 'initializing...'
      @close_proc.call if @close_proc # reset in case they call start twice
      begin
        @close_proc, @overlay, edl_url = go_online parent_window, just_screen_snapshot, movie_url, amazon_episode_number, player_description_path
        if @close_proc
          path = Pathname.new player_description_path
          @now_playing_label.set_text "player: #{path.parent.basename}/#{path.basename} #{edl_url.split('/')[-1]}" 
          @now_playing_label2.set_text "currently editing for this movie: #{movie_url}" # movie name somehow? extract from movie_url? get from edl?
        end
      rescue OpenURI::HTTPError => e
        puts "offending trace"
        puts e.backtrace
        show_blocking_message_dialog "uh oh, cinemasoap website possibly down [please report it]? #{e}\n #{movie_url}"
      end
    end
    
    def setup_online_player_buttons
      require_relative '../online_movie_players.rb'	 
      add_text_line 'Online Player playback Options:'

      test_video_url = "https://www.netflix.com/watch/60020424?trackId=13727493&tctx=0%2C0%2C86c3b87f-393a-4913-9f7d-5bd95544b831-96236411"

      new_jbutton("Start edited playback") do
        movie_url = SimpleGuiCreator.get_user_input "please enter movie url, like http://www.amazon.com/gp/product/B004RFZODC [etc.]", test_video_url # TODO cache last used?
        if movie_url =~ /amazon.com/
          amazon_episode_number = SimpleGuiCreator.get_user_input "If it is a specific episode on amazon, enter episode number, otherwise leave at 0", "0"
        else
          amazon_episode_number = "0"
        end
        # TODO player_description_path = AutoWindowFinder.search_for_player_and_url_match(players_root_dir)
        # assume netflix full screen for now LOL
        # players_root_dir = __DIR__ + "/../../zamples/players"
        # player_description_path = choose_file("     SELECT MOVIE PLAYER YOU INTEND ON USING", players_root_dir)
        player_description_path = "./zamples/player/netflix/netflix_fullscreen.txt" # TODO
        start_new_run self, false, movie_url, amazon_episode_number, player_description_path
      end            

      new_jbutton("Stop edited playback") do
        @close_proc.call if @close_proc
      end            

      new_jbutton("Open Website for viewing/editing all movie edit choice lists") do
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://cleanstream.inet2.org/"
      end

      @online_status_label = add_text_line "Player status:"
      @playing_well_label = add_text_line "Status: hit start to being..."
      @playing_well_label2 = add_text_line ""
      @now_playing_label = add_text_line ""
      @now_playing_label2 = add_text_line ""

      # add_open_documentation_button # not pertinent enough yet...	  
      if ARGV.contain?('--advanced')
      
        path = File.dirname(__FILE__) + "/../../zamples/players/amazon/total_length_over_an_hour.txt"
        autostart = new_jbutton("Auto start edited playback for testing") do
          start_new_run self, false, test_video_url, "0", path          
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
