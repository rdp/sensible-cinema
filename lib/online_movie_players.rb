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

def go_sc()
  
  OCR.clear_cache!
  puts 'cleared cache'
  
  players_root_dir = __DIR__ + "/../zamples/players"
  # allow for command line filenames
  player_description = args.shift
  unless player_description
    player_description = AutoWindowFinder.search_for_player_and_url_match(players_root_dir)
    if player_description
      p 'auto selected player ' + player_description 
    else
      player_description = ''
    end
  end
  
  if !File.exist?(player_description)    
    puts 'Please Select Computer Player'
    player_description = choose_file("     SELECT COMPUTER PLAYER", players_root_dir)
    raise unless player_description
  end
   
  edit_decision_list = args.shift.to_s

  if edit_decision_list == 'test' # TODO test option!
    overlay = nil
    p 'got test...just doing screen dump'
    $VERBOSE=true # adds some extra output
  elsif File.exist? edit_decision_list
    # accept it from the command line
  else
    auto_found = AutoWindowFinder.search_for_single_url_match
    if auto_found
      p 'auto-discovered open window for player x EDL, using it ' + auto_found
      edit_decision_list = auto_found
    else
      puts 'Select Edit Decision List to use'
      edit_decision_list = choose_file("     SELECT EDIT DECISION LIST", __DIR__  + "/../zamples/edit_decision_lists")
    end
    url = SimpleGuiCreator.get_user_input "please enter url with edits, like http://.../view/name"
    edl = SensibleSwing::MainWindow.download_to_string url
    settings = EdlParser.parse_string edl
    
    Blanker.startup
    # todo start it late as it has an annoying startup blip
  end
  overlay = OverLayer.new(edit_decision_list) if edit_decision_list
  
  if File.exist? player_description.to_s
    puts 'Selected player ' + File.basename(player_description) + "\n\t(full path: #{player_description})"
    # this one doesn't use any updates, so just pass in file contents, not filename
    screen_tracker = ScreenTracker.new_from_yaml File.binread(player_description), overlay
    does_not_need_mouse_jerk = YAML.load_file(player_description)["does_not_need_mouse_movement"]
    unless does_not_need_mouse_jerk
      p 'yes using mouse jitter' if $VERBOSE or $DEBUG
      Mouse.jitter_forever_in_own_thread # when this ends you know a snapshot was taken...
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
  Mouse.move_mouse_relative 0, 10 # LODO 
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
