#!/usr/bin/ruby
=begin
Copyright 2014, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end

for file in ['overlayer', 'status_line', 'screen_tracker', 'ocr', 'vlc_programmer', 'edl_parser', 'auto_window_finder', 'jruby-swing-helpers/lib/simple_gui_creator/swing_helpers', 'jruby-swing-helpers/lib/simple_gui_creator/mouse_control']
  require_relative file
end

def choose_file title, dir
  SimpleGuiCreator.new_previously_existing_file_selector_and_go title, dir
end

def go_online parent_window, just_screen_snapshot = false, url = nil, player_description_path = nil
  
  OCR.clear_cache! # ??
  puts 'cleared OCR cache'
  
  players_root_dir = __DIR__ + "/../zamples/players"
  # TODO
  # player_description_path = AutoWindowFinder.search_for_player_and_url_match(players_root_dir)
  if player_description_path
    p 'using auto selected player ' + player_description_path 
  else
    player_description_path = ''
  end
  
  if !File.exist?(player_description_path)    
    puts 'Please Select Your Movie Player'
    player_description_path = choose_file("     SELECT MOVIE PLAYER", players_root_dir)
    raise unless player_description_path
  end
   
  if just_screen_snapshot
    p 'just doing [only] screen dump...'
    $VERBOSE=true # also add some extra output
  elsif url
    # accept url...
  else
    # TODO auto_found_url = AutoWindowFinder.search_for_single_url_match
    # TODO migrate these to onliners [the online playback ones]: "/../zamples/edit_decision_lists"
	  # TODO migrate DVD;ers too :)
	  url = SimpleGuiCreator.get_user_input "please enter url to use, like http://198.199.93.93/view/abc?raw=1"    
  end
  
  if url
    overlay = OverLayer.new(url)
	  Blanker.warmup
  end
  
  puts 'Selected player: ' + File.basename(player_description_path) + "\n\t(full path: #{player_description_path})"
  # this one doesn't use any updates, so just pass in file contents, not filename
  screen_tracker = ScreenTracker.new_from_yaml File.binread(player_description_path), overlay
  does_not_need_mouse_jerk = YAML.load_file(player_description_path)["does_not_need_mouse_movement"]
  unless does_not_need_mouse_jerk
    p 'yes using mouse jitter' if $VERBOSE or $DEBUG
    MouseControl.jitter_forever_in_own_thread # when this ends you know a snapshot was taken...
  else
    p 'not using mouse jitter' if $VERBOSE or $DEBUG
  end

  # exit early if we just wanted a screen dump...a little kludgey...
  if overlay
    screen_tracker.process_forever_in_thread
  else
    puts 'warning--only doing screen dump in t-minus 2s...'      
    sleep 2
    screen_tracker.dump_bmps
    puts 'done snap!'
    exit 1
  end
  
  OCR.unserialize_cache_from_disk # do this every time so we don't overwrite it ever on accident

  p 'moving mouse to align it for muting down 10' # ??
  MouseControl.move_mouse_relative 0, 10 # LODO 
  overlay.start_thread true
  status_line = StatusLine.new overlay
  status_line.start_thread
  
  puts "Opening the curtains, all systems started... (please play in your other video player now)"
  
  close_proc = proc {
    Blanker.shutdown 
    screen_tracker.shutdown
    OCR.serialize_cache_to_disk
    MouseControl.shutdown
    overlay.shutdown
    #screen_tracker.thread.join # XXX
    status_line.shutdown
    puts 'done shuttting down'
  }
  parent_window.after_closed { close_proc.call } # just in case
  close_proc

end
