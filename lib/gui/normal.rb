#!/usr/bin/ruby # so my editor will like the file...
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

module SensibleSwing
  
  class MainWindow < JFrame

    attr_accessor :parent, :upconv_line
   
    def setup_normal_buttons
      add_text_line ""
  
      @mplayer_edl = new_jbutton( watch_edited_text="Watch currently mounted DVD edited (realtime)" )
      @mplayer_edl.tool_tip = "This will watch your DVD in realtime from your computer while skipping/muting questionable scenes."
      @mplayer_edl.on_clicked {
        play_smplayer_edl_non_blocking
      }
      
      add_callback_for_dvd_edl_present { |disk_available, edl_available|
        b = @mplayer_edl
	    if disk_available
			if edl_available
			  b.enable
			  b.text=watch_edited_text
			else
			  b.enable # leave it enabled in case it's some nonstandard form of a disk that does have one [?]
			  b.text= watch_edited_text + "  [disk has no Edit List Available!]" 
			end
		else
		  @mplayer_edl.disable
		  @mplayer_edl.text=watch_edited_text + " [no disk presently inserted]"
		end
      }
      
      @watch_file_edl = new_jbutton( "Watch movie file edited (realtime)" ) do
        force_accept_file_style_license
        choose_file_and_edl_and_create_sxs_or_play false
      end
      
      if LocalStorage[UpConvertEnglish] # LODO no tight coupling like this
        add_text_line ''
        add_open_documentation_button
        @upconv_line = add_text_line "    #{get_current_upconvert_as_phrase}"
      else
        @upconv_line = add_text_line ''
        add_open_documentation_button
      end
      
      @show_upconvert_options = new_jbutton("Tweak Preferences [timing, upconversion]") do
	    set_individual_preferences
        show_blocking_message_dialog "You will now be able to set some upconversion options, which makes the playback look nicer but uses more cpu [if desired].\nClose the window when finished."
        upconvert_window = new_child_window
        upconvert_window.add_change_upconvert_buttons
      end
      @show_upconvert_options.tool_tip= "Allows you to set your upconvert options.\nUpconverting attempts to playback your movie with higher quality on high resolution monitors."
      
 	    new_jbutton("Create new/edit Edit Decision List for a DVD or File") do
	      window = new_child_window
          window.setup_create_buttons
	    end
		
        @upload = new_jbutton("Feedback/questions welcome!") # keeps this one last! :)
        @upload.tool_tip = "We welcome all feedback!\nQuestion, comments, request help.\nAlso if you create a new EDL, please submit it back to us so that others can benefit from it later!"
        @upload.on_clicked {
		      show_blocking_message_dialog "ok, next it will open up the web page which has some contact links at the bottom"
          system_non_blocking("start http://cleaneditingmovieplayer.inet2.org/")
        }
        increment_button_location
	  
    end
    
    # side by side stuff we haven't really factored out yet, also doubles for both normal/create LODO
    def choose_file_and_edl_and_create_sxs_or_play just_create_xbmc_dot_edl_file_instead_of_play
      filename_mpg = new_existing_file_selector_and_select_file( "Pick moviefile (like moviename.mp4, moviename.mpg or video_ts/anything.ext)")
      edl_filename = new_existing_file_selector_and_select_file( "Pick an EDL file to use with it (for none yet, right click and create new text file)", EdlParser::EDL_DIR)
      if just_create_xbmc_dot_edl_file_instead_of_play
        descriptors = EdlParser.parse_file edl_filename
        # XBMC can use english timestamps
        edl_contents = MplayerEdl.convert_to_edl descriptors, add_secs_end = 0.0, begin_buffer_preference, splits = [], extra_time_to_all = 0.0, use_english_timestamps=true
        output_file = filename_mpg.gsub(/\.[^\.]+$/, '') + '.edl' # sanitize...
        File.write(output_file, edl_contents)
        raise unless File.exist?(output_file) # sanity
        show_blocking_message_dialog("created #{output_file}")
      else
        play_smplayer_edl_non_blocking [filename_mpg, edl_filename]
      end
    end
    
    
  end
end

