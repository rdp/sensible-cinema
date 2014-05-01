#!/usr/bin/ruby
=begin
Copyright 2010, Roger Pack 
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

for file in ['overlayer', 'keyboard_input', 'screen_tracker', 'ocr', 'vlc_programmer', 'edl_parser', 'auto_window_finder', 'jruby-swing-helpers/lib/simple_gui_creator/swing_helpers', 'jruby-swing-helpers/lib/simple_gui_creator/mouse_control']
  require_relative file
end

def choose_file title, dir
  SimpleGuiCreator.new_previously_existing_file_selector_and_go title, dir
end

def go_online screen_snapshot = false, url = "http://198.199.93.93/view/abc?raw=1"
  
  OCR.clear_cache!
  puts 'cleared OCR cache'
  
  players_root_dir = __DIR__ + "/../zamples/players"
  # allow for command line filenames
  # TODO
  # player_description = AutoWindowFinder.search_for_player_and_url_match(players_root_dir)
  player_description = nil
  if player_description
    p 'auto selected player ' + player_description 
  else
    player_description = ''
  end
  
  if !File.exist?(player_description)    
    puts 'Please Select Your Movie Player'
    player_description = choose_file("     SELECT MOVIE PLAYER", players_root_dir)
    raise unless player_description
  end
   
  if screen_snapshot
    p 'got test...just doing screen dump'
    $VERBOSE=true # add some extra output
  elsif url
    # accept it
  else
    # TODO auto_found_url = AutoWindowFinder.search_for_single_url_match
    # TODO migrate these to onliners [the online playback ones]: "/../zamples/edit_decision_lists"
	# TODO migrate DVDzers too :)
	url = SimpleGuiCreator.get_user_input "please enter url to use, like http://198.199.93.93/view/abc?raw=1"
    Blanker.startup
    # todo start it later as it has an annoying startup blip, or something
  end
  overlay = OverLayer.new(url) if url
  
  if File.exist? player_description.to_s
    puts 'Selected player ' + File.basename(player_description) + "\n\t(full path: #{player_description})"
    # this one doesn't use any updates, so just pass in file contents, not filename
    screen_tracker = ScreenTracker.new_from_yaml File.binread(player_description), overlay
    does_not_need_mouse_jerk = YAML.load_file(player_description)["does_not_need_mouse_movement"]
    unless does_not_need_mouse_jerk
      p 'yes using mouse jitter' if $VERBOSE or $DEBUG
      MouseControl.jitter_forever_in_own_thread # when this ends you know a snapshot was taken...
    else
      p 'not using mouse jitter' if $VERBOSE or $DEBUG
    end
    
    # exit early if we just wanted a screen dump...a little kludgey...
    unless overlay
      puts 'warning--only doing screen dump in t-minus 2s...'      
      sleep 2
      puts 'snap!'
      screen_tracker.dump_bmps
      exit 1
    end
    screen_tracker.process_forever_in_thread
  else
    puts 'warning--not using any screen tracking...'
  end
  
  OCR.unserialize_cache_from_disk # do this every time so we don't delete it if they don't have one...???

  p 'moving mouse to align it for muting down 10'
  MouseControl.move_mouse_relative 0, 10 # LODO 
  puts "Opening the curtains... (please play in your other video player now)"
  overlay.start_thread true
  key_input = KeyboardInput.new overlay
  key_input.start_thread # status thread
  at_exit {
    Blanker.shutdown # lodo move this and the 'q' key to within overlayer
    OCR.serialize_cache_to_disk
  }
  key_input.handle_keystrokes_forever # blocking...
end
