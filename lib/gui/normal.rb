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
   
    # converts to full path, 8.3 if on doze
    def normalize_path path
      path = File.expand_path path
      path = EightThree.convert_path_to_8_3 path if OS.doze?
    end

    def hard_exit; java::lang::System.exit 0; end

    def setup_normal_buttons
      add_text_line ""
  
      @mplayer_edl = new_jbutton( watch_edited_text="Watch currently mounted DVD edited (realtime)" )
      @mplayer_edl.tool_tip = "This will watch your DVD in realtime from your computer while skipping/muting questionable scenes."
      @mplayer_edl.on_clicked {
        play_smplayer_edl_non_blocking
	sleep 5
	puts 'enjoy your movie playing in other window'
        sleep 1
	hard_exit if OS.doze? # paranoid on cpu usage LOL LODO mac too? it kills mplayer child processes currently...hmm...
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
      
      @create = new_jbutton( "Create edited version of a file on Your Hard Drive" )
      @create.tool_tip = <<-EOL
        This takes a file and creates a new file on your hard disk like dvd_name_edited.mpg that you can watch when it's done.
        The file you create will contain the whole movie edited.
        It takes quite awhile maybe 2 hours.  Sometimes the progress bar will look paused--it typically continues eventually.
      EOL
      @create.on_clicked {
        force_accept_file_style_license
  	    check_for_file_manipulation_dependencies
        do_create_edited_copy_via_file false
      }
      
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
      
 	    new_jbutton("Create new Edit Decision List") do
	      window = new_child_window
        window.setup_create_buttons
	    end
	  
      @progress_bar = JProgressBar.new(0, 100)
      @progress_bar.set_bounds(44,@starting_button_y,@button_width,23)
      @progress_bar.visible = false
      @panel.add @progress_bar 
      add_text_line ""# spacing
    end
	
	def set_individual_preferences
      get_set_preference 'mplayer_beginning_buffer', "How much extra \"buffer\" time to add at the beginning of all cuts/mutes in normal mode [for added safety sake]."
      if JOptionPane.show_select_buttons_prompt("Would you like to use this with Zoom Player MAX's scene cuts [3rd party player program, costs $], or just MPlayer [free]", :no => "ZoomPlayer MAX", :yes => "Just MPlayer [free]") == :no
        LocalStorage['have_zoom_button'] = true
      else
	    LocalStorage['have_zoom_button'] = false
	  end
	  true
	end
    
    def get_set_preference name, english_name
      old_preference = LocalStorage[name]
      old_class = old_preference.class
      new_preference = get_user_input("Enter value for #{english_name}", old_preference)
      display_and_raise 'enter something like 0.0' if new_preference.empty?
      if old_class == Float
        new_preference = new_preference.to_f
      elsif old_class == String
        # leave same
      else
        raise 'unknown type?' + old_class.to_s
      end
      LocalStorage[name] = new_preference
    end
    
    def add_open_documentation_button
      @open_help_file = new_jbutton("View Sensible Cinema Documentation") do
        show_in_explorer __DIR__ + "/../../documentation"
      end
    end
    
    # side by side stuff we haven't really factored out yet, also doubles for both normal/create LODO
    def choose_file_and_edl_and_create_sxs_or_play just_create_xbmc_dot_edl_file_instead_of_play
      filename_mpg = new_existing_file_selector_and_select_file( "Pick moviefile (like moviename.mpg or video_ts/anything.ext)")
      edl_filename = new_existing_file_selector_and_select_file( "Pick an EDL file to use with it", EdlParser::EDL_DIR)
      assert_ownership_dialog
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

