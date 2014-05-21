
module SensibleSwing
  
  class MainWindow
  
    def start_new_run *args
      @close_proc.call if @close_proc
      @close_proc = go_online *args
    end
    
    def setup_online_player_buttons
      require_relative '../online_movie_players.rb'	 
      add_text_line 'Online Player playback Options:'

      new_jbutton("Start edited playback") do
        start_new_run self
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
      if ARGV.contain?('--advanced')
      
        path = File.dirname(__FILE__) + "/../../zamples/players/amazon/total_length_over_an_hour.txt"
        url = "http://cinemasoap.inet2.org/view/abc?raw=1"
        autostart = new_jbutton("Auto start edited playback for testing") do
          start_new_run self, false, url, path          
        end
        new_jbutton("Take snapshot of player descriptor") do
          start_new_run self, true, url, path
        end
        autostart.click!
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
