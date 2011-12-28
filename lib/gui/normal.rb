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
  
      @mplayer_edl = new_jbutton( "Watch currently mounted DVD edited (realtime)" )
      @mplayer_edl.tool_tip = "This will watch your DVD in realtime from your computer while skipping/muting questionable scenes."
      @mplayer_edl.on_clicked {
        play_smplayer_edl_non_blocking
		puts 'enjoy your movie playing in other window'
        sleep 5
		java::lang::System.exit 0 # paranoid on usage LOL
      }
      
      add_callback_for_dvd_edl_present { |disk_available, edl_available|
        if edl_available
          @mplayer_edl.enable
        else
          @mplayer_edl.disable
        end
      }
      
      @watch_file_edl = new_jbutton( "Watch movie file edited (realtime)" ) do
        choose_file_and_edl_and_create_sxs_or_play false
      end
      
      @create = new_jbutton( "Create edited version of a file on Your Hard Drive" )
      @create.tool_tip = <<-EOL
        This takes a file and creates a new file on your hard disk like dvd_name_edited.mpg that you can watch when it's done.
        The file you create will contain the whole movie edited.
        It takes quite awhile maybe 2 hours.  Sometimes the progress bar will look paused--it typically continues eventually.
      EOL
      @create.on_clicked {
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
        get_set_preference 'mplayer_beginning_buffer', "How much extra \"buffer\" time to add at the beginning of all cuts/mutes in normal mode [for added safety sake]."
        show_blocking_message_dialog "You will now be able to set some upconversion options, which makes the playback look nicer but uses more cpu [if desired].\nClose the window when finished."
        upconvert_window = new_child_window
        upconvert_window.add_change_upconvert_buttons
      end
      @show_upconvert_options.tool_tip= "Allows you to set your upconvert options.\nUpconverting attempts to playback your movie with higher quality on high resolution monitors."
      
      @progress_bar = JProgressBar.new(0, 100)
      @progress_bar.set_bounds(44,@starting_button_y,@button_width,23)
      @progress_bar.visible = false
      @panel.add @progress_bar 
      add_text_line ""# spacing
    end
    
    def get_set_preference name, english_name
      old_preference = LocalStorage[name]
      old_class = old_preference.class
      new_preference = get_user_input("Enter value for #{english_name}", old_preference)
      raise if new_preference.empty?
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
    def choose_file_and_edl_and_create_sxs_or_play just_create_dot_edl_file_instead_of_play
      filename_mpg = new_existing_file_selector_and_select_file( "Pick moviefile (like moviename.mpg or video_ts/anything.ext)")
      edl_filename = new_existing_file_selector_and_select_file( "Pick an EDL file to use with it", EdlParser::EDL_DIR)
      assert_ownership_dialog
      if just_create_dot_edl_file_instead_of_play
        descriptors = EdlParser.parse_file edl_filename
        # LODO these timings...DRY up...plus is XBMC the same? what about on a slower computer?
        # NB these are just for the Side by side EDL's!
        
        edl_contents = MplayerEdl.convert_to_edl descriptors, add_secs_end = MplayerEndBuffer, MplayerBeginingBuffer, splits = []
        output_file = filename_mpg.gsub(/\.[^\.]+$/, '') + '.edl' # sanitize...
        File.write(output_file, edl_contents)
        raise unless File.exist?(output_file)
        show_blocking_message_dialog("created #{output_file}")
      else
        play_smplayer_edl_non_blocking [filename_mpg, edl_filename]
      end
    end
    
    def we_are_in_upconvert_mode
       ARGV.index("--upconvert-mode")
    end
    
    def setup_default_buttons
      if we_are_in_upconvert_mode
        add_play_upconvert_buttons
      else
        if we_are_in_create_mode
          setup_advanced_buttons
          add_text_line 'Contact:'
        else
          setup_normal_buttons
        end
      
        @upload = new_jbutton("Feedback/submissions welcome!") # keeps this one last! :)
        @upload.tool_tip = "We welcome all feedback!\nQuestion, comments, request help.\nAlso if you create a new EDL, please submit it back to us so that others can benefit from it later!"
        @upload.on_clicked {
          system_non_blocking("start mailto:sensible-cinema@googlegroups.com")
          system_non_blocking("start http://groups.google.com/group/sensible-cinema")
        }
        increment_button_location

      end # big else
      
      @exit = new_jbutton("Exit", "Exits the application and kills any background processes that are running at all--don't exit unless you are done processing all the way!")
      @exit.on_clicked {
        Thread.new { self.close } # don't waste the time to close it :P
        puts 'Thank you for using Sensible Cinema. Come again!'
        System.exit 0
      }

      increment_button_location
      increment_button_location
      self

    end
    def get_disk_chooser_window names
      DropDownSelector.new(self, names, "Click to select DVD drive")
    end
    
  end
end

