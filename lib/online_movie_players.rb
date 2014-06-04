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

def go_online parent_window, just_screen_snapshot, movie_url, player_description_path
  
  OCR.clear_cache! # ??
  puts 'cleared OCR cache'
  
  if just_screen_snapshot
    $VERBOSE=true # also add some extra output
    raise if movie_url
  else
    query_url = "http://cinemasoap.inet2.org/search?movieurl=" + movie_url
    edl_url = SensibleSwing::MainWindow.download_to_string query_url
    if edl_url =~ /not found/
      webpage_itself = SensibleSwing::MainWindow.download_to_string movie_url
      webpage_itself =~ /<title>(.*)<\/title>/i
      SimpleGuiCreator.show_message "movie not yet in our database, please edit/add it now"   # TODO pass in url, it assigns it smartly?
      if $1
         movie_name = $1.split(' | ')[0] # moviename | hulu => moviename
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://cinemasoap.inet2.org/new?moviename=#{movie_name}&movieurl=#{movie_url}" # TODO  use movieurl
      else
         SimpleGuiCreator.open_url_to_view_it_non_blocking "http://cinemasoap.inet2.org/" # index page  has add at the bottom :)
      end
      return nil
    end
    overlay = OverLayer.new(edl_url)
  end
  
  # this one doesn't use any updates, so just pass in file contents, not filename
  screen_tracker = ScreenTracker.new_from_yaml File.binread(player_description_path), overlay, parent_window
  does_not_need_mouse_jerk = YAML.load_file(player_description_path)["does_not_need_mouse_movement"]
  unless does_not_need_mouse_jerk
    p 'yes using mouse jitter' if $VERBOSE or $DEBUG
    MouseControl.jitter_forever_in_own_thread # when this ends you know a snapshot was taken...
  else
    p 'not using mouse jitter' if $VERBOSE or $DEBUG
  end

  # exit early if we just wanted a screen dump...a little kludgey...
  if !just_screen_snapshot
    Blanker.warmup
    screen_tracker.process_forever_in_thread
  else
    parent_window.update_playing_well_status 'warning--only doing screen dump in t-minus 2s...'      
    Thread.new {
      # new thread so the UI can get the above message :)
      sleep 2
      screen_tracker.dump_bmps
      parent_window.update_playing_well_status 'done snap!'
    }
    return nil
  end
  
  OCR.unserialize_cache_from_disk # do this every time so we don't overwrite it ever on accident with a fresh blank slate and lose everything

  overlay.start_thread true
  callback = proc { |status|
    parent_window.update_online_player_status status
  }
  status_line = StatusLine.new overlay, callback
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
  [close_proc, overlay, edl_url]
end
