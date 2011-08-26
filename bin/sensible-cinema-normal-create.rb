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

    SideBySide = 'side_by_side' # 'xbmc' or 'smplayer'
    
    def select_new_sxs_style
      answer = show_select_buttons_prompt 'Select EDL file style creation for this program', :yes => 'Smplayer style', :no => 'XBMC style'
      if answer == 0
        LocalStorage[SideBySide] = 'smplayer'
      elsif answer == 1
        LocalStorage[SideBySide] = 'xbmc'
      else
        show_blocking_message_dialog 'please choose one--smplayer if you don\'t know'
        select_new_sxs_style
      end
        
    end
      
    attr_accessor :parent, :upconv_line
    
    def setup_advanced_buttons
    
      new_jbutton("Display the standard buttons") do
        window = new_child_window
        window.setup_normal_buttons
      end
    
      add_text_line 'Realtime/Create Options:'
      
      @create_new_edl_for_current_dvd = new_jbutton("Create new Edit List for a DVD", 
        "If your DVD doesn't have an EDL created for it, this will be your first step--create an EDL file for it.")
      @create_new_edl_for_current_dvd.on_clicked do
        create_brand_new_edl
        @display_dvd_info.simulate_click # for now...
      end
      
      @open_list = new_jbutton("Open/Edit a previously created Edit List file", "If your DVD has a previously existing EDL for it, you can open it to edit it with this button.")
      @open_list.on_clicked {
        filename = new_existing_file_selector_and_select_file( "Pick any file to open in editor", EdlParser::EDL_DIR)
        open_file_to_edit_it filename
      }
      
      @play_smplayer = new_jbutton( "Watch full DVD unedited (realtime smplayer)")
      @play_smplayer.tool_tip = <<-EOL
        This will play the DVD unedited within smplayer.
        NB it will default to title 1, so updated your EDL file that matches this DVD with the proper title if this doesn't work for you 
        i.e. if it just plays a single preview title or what not, and not the main title, you need to change this value.
        This is useful if you want to just kind of watch the movie to enjoy it, and look for scenes to cut out.
        You can use the built-in OSD (on-screen-display) to see what time frame the questionable scenes are at
        (type "o" to toggle it).  However, just realize that the OSD is in 30 fps, and our time stamps are all in 29.97
        fps, so you'll need to convert it (the convert timestamp button) to be able to use it in a file.
      EOL
      @play_smplayer.on_clicked {
        play_dvd_smplayer_unedited false, true, true
      }

      @play_mplayer_raw = new_jbutton( "Watch full DVD unedited (realtime mplayer)")
      @play_mplayer_raw.tool_tip = <<-EOL
        This is also useful for comparing subtitle files to see if they have accurate timings.
        If you turn on subtitles (use the v button), then compare your srt file at say, the 1 hour mark, or 2 hour mark,
        with the subtitles that mplayer displays, it *should* match exactly with the output in the command line,
        like "V: 3600.0" should match your subtitle line "01:00:00,000 --> ..."
      EOL
      @play_mplayer_raw.on_clicked {
        play_dvd_smplayer_unedited true, true, true
      }
      
      @parse_srt = new_jbutton("Scan a subtitle file (.srt) to detect profanity times automatically" )
      @parse_srt.tool_tip = <<-EOL
        You can download a .srt file and use it to automatically search for profanities.
        Basically download it from opensubtitles.org (possibly from other sites, too),
        (enter dvd name in the search box, click a result, click one from the list with an English flag, then click 'Download(zip)')
        Once you download the zip, unzip it, and then compare the timestamps in it with those on the DVD (see the button "Watch DVD unedited (realtime mplayer)")
        NB that you'll first want/need to *carefully* double check your subtitle
        file with the actual DVD.  (ex: smplayer, hit the 'o' button to display
        the current timestamp, then go to the end, stop at some point with text
        and hit the '.' key until a subtitle very first displays.
        Next convert that number to 29.97 fps (using the button given).
        The numbers should match precisely.  If they don't, edit this file
        so that it will have some offsets given.
      EOL

      @parse_srt.on_clicked do
        filename = new_existing_file_selector_and_select_file("Pick srt file to scan for profanity:")
        add_to_beginning = get_user_input("How much time to subtract from the beginning of each subtitle entry (ex: 1:00 -> 1:01 becomes 0:59 -> 1:01)", "0.0")
        add_to_end = get_user_input("How much time to add to the end of each subtitle entry (ex: 1:00 -> 1:01 becomes 1:00 -> 1:02)", "0.0")
        parsed = SubtitleProfanityFinder.edl_output filename, {}, add_to_beginning.to_f, add_to_end.to_f # flight: TODO necessary typically ??? 0.35, 0.25 
        File.write(EdlTempFile, "# add these into your mute section if you deem them mute-worthy\n" + parsed)
        open_file_to_edit_it filename, true
        sleep 0.3 if OS.mac? # add delay...
        open_file_to_edit_it EdlTempFile
      end

      @display_dvd_info = new_jbutton( "Display information about current DVD (ID, etc.)" )
      @display_dvd_info.tool_tip = "This is useful to setup a DVD's 'unique ID' within an EDL for it. \nIf your EDL doesn't have a line like disk_unique_id => \"...\" then you will want to run this to be able to add that line in."
      @display_dvd_info.on_clicked {
        drive, volume_name, dvd_id = choose_dvd_drive_or_file true # real DVD disk
        # display it, allow them to copy and paste it out
        title_lengths = nil
        t = Thread.new { title_lengths= `mplayer dvdnav:// -nocache -dvd-device #{drive} -identify -frames 0 2>&1| grep LENGTH` }
        id_string = "\"disk_unique_id\" => \"#{dvd_id}\", # #{volume_name}"
        show_copy_pastable_string "#{drive} #{volume_name} for your copying+pasting pleasure (highlight, then ctrl+c to copy)\n
        This is USED eventually to identify a disk to match it to its EDL, later.", id_string
        t.join
        File.write EdlTempFile, id_string + "\n" + title_lengths
        open_file_to_edit_it EdlTempFile
        id_string
      }

      @convert_seconds_to_ts = new_jbutton( "Convert 3600 <-> 1:00:00 style timestamps" )
      @convert_seconds_to_ts.on_clicked {
        input = get_user_input("Enter \"from\" timestamps, like 3600 or 1:40:00:", "1:00:00.1 or 3600.1")
        while(input)
          if input =~ /:/
            output = EdlParser.translate_string_to_seconds input
          else
            output = EdlParser.translate_time_to_human_readable input.to_f, true
          end 
          input = show_copy_pastable_string("Converted:", output)         
        end
      }
      
      @convert_timestamp = new_jbutton( "Convert timestamp from DVD player time to EDL time (30->29.97 fps)" )
      @convert_timestamp.tool_tip=<<-EOL
        Our EDL's assume 29.97 fps (which is what a DVD actually has).  Unfortunately most hardware or commercial DVD players
        think that the DVD is 30 fps, which means that if you use them for timestamps for your EDL's,
        you will be slightly off (at the end of a 2 hour film, by 8 seconds).  So all your edits will be wrong.
        How to fix: convert your times from "DVD player" time to "EDL accurate" time by using this button.
        This is necessary for all hardware DVD player timestamps, PowerDVD player (software), Windows Media Player (playing a DVD), 
        and mplayer's "on screen display" DVD timestamps.
        It is not necessary for smplayer timestamps (or mplayer's "V: 3600" in the command line), which are already 29.97.
        smplayer's on-screen-display (the 'o' key) is accurate (and doesn't suffer from dvd_mplayer_splits) 
        but is 30 fps, so timestamps would need to be converted.
        Dont use VLC for DVD timestamps at all--it can get up to 30s off!  VLC playing back a file is usually pretty accurate to 29.97.
        In general, GUI's like VLC or smplayer are always a tidge off (maybe 0.3s) from the right timestamp, so take that into consideration.
        Mplayers "V: 3600" is usually right on (29.97 fps), however.
      EOL
      @convert_timestamp.on_clicked {
        thirty_fps = get_user_input("Enter your DVD (30 fps) timestamp, I'll convert it to 29.97 (usable in EDL's):", "1:00:00.1")
        thirty_fps_in_seconds = EdlParser.translate_string_to_seconds thirty_fps
        twenty_nine_seven_fps = ConvertThirtyFps.from_thirty(thirty_fps_in_seconds)
        human_twenty_nine_seven = EdlParser.translate_time_to_human_readable twenty_nine_seven_fps, true
        show_copy_pastable_string("Sensible cinema usable value (29.97 fps) for #{thirty_fps} would be:                ", human_twenty_nine_seven)
      }
      
      @create_dot_edl = new_jbutton( "Create a side-by-side moviefilename.edl file")
      @create_dot_edl.tool_tip = <<-EOL
        Creates a moviefilename.edl file (corresponding to some moviefilename.some_ext file already existing)
        XBMC/smplayer (smplayer can be used by WMC plugins, etc.) "automagically detect", 
        if it exists, and automatically use it .edl to show that file edited played back.
        If you use smplayer, note that you'll need to download the "lord mulder mplayer"
        version (which includes an updated version of mplayer that fixes some bugs in EDL playback)
      EOL
      @create_dot_edl.on_clicked {
        choose_file_and_edl_and_create_sxs_or_play true
      }
      
#      new_jbutton("Select side by side EDL file style (smplayer vs. XBMC)") do
#        select_new_sxs_style # TODO
#      end

      
      add_text_line 'Create Options with local intermediary file:'
      
      new_jbutton("Show options with local intermediary file") do
        window = new_child_window
        window.add_options_that_use_local_files
      end
      
#      @reload = new_jbutton("reload bin/sensible-cinema code") do
#        load $0
#      end
      
    end # advanced buttons
    
    def add_options_that_use_local_files
      add_text_line 'Create Options that first create/use a local intermediary file:'

      @preview_section = new_jbutton( "Preview a certain time frame from fulli file (edited)" )
      @preview_section.tool_tip = <<-EOL
        This allows you to preview an edit easily.
        It is the equivalent of saying \"watch this file edited from exactly minute x second y to minute z second q"
        Typically if you want to test an edit, you can start a few seconds before, and end a few seconds after it, to test it precisely.
      EOL
      @preview_section.on_clicked {
        do_create_edited_copy_via_file true
      }
      
      @preview_section_unedited = new_jbutton("Preview a certain time frame from fulli file (unedited)" )
      @preview_section.tool_tip = "Allows you to view a certain time frame unedited (ex: 10:00 to 10:05), so you can narrow down to pinpoint where questionable scenes are, etc. This is the only way to view a specific scene if there are not cuts within that scene yet."
      @preview_section_unedited.on_clicked {
        do_create_edited_copy_via_file true, false, true
      }

      @rerun_preview = new_jbutton( "Re-run most recently watched preview time frame from fulli file" )
      @rerun_preview.tool_tip = "This will re-run the preview that you most recently performed.  Great for checking to see if you last edits were successful or not."
      @rerun_preview.on_clicked {
        repeat_last_copy_dvd_to_hard_drive
      }
      
      # Maybe this button should go too...
      @fast_preview = new_jbutton("fast preview all from fulli file (smplayer EDL)")
      @fast_preview.tool_tip = <<-EOL
        Plays smplayer on a file with an EDL.
        This gives you a rough estimate to see if your edits are accurate, and is really fast to seek, etc.
        This is useful because you can't use mplayer on a DVD for accurate timestamps if it has any 
        timestamp splits in it [because some DVD's are buggy]
      EOL
      @fast_preview.on_clicked {
        success, wrote_to_here_fulli = do_create_edited_copy_via_file false, true
        sleep 0.5 # lodo take out ???
        background_thread.join if background_thread # let it write out the original fulli, if necessary [?]
        nice_file = wrote_to_here_fulli
        run_smplayer_blocking nice_file, nil, "-edl #{normalize_path EdlTempFile}", false, true
      }
    end
   
    # converts to full path, 8.3 if on doze
    def normalize_path path
      path = File.expand_path path
      path = EightThree.convert_path_to_8_3 path if OS.doze?
    end

    def setup_normal_buttons
      add_text_line ""
  
      @mplayer_edl = new_jbutton( "Watch DVD edited (realtime)")
      @mplayer_edl.tool_tip = "This will watch your DVD in realtime from your computer while skipping/muting questionable scenes."
      @mplayer_edl.on_clicked {
        play_mplayer_edl_non_blocking 
      }
      
      @create = new_jbutton( "Create edited copy of DVD/file on Your Hard Drive" )
      @create.tool_tip = <<-EOL
        This takes a file and creates a new file on your hard disk like dvd_name_edited.mpg that you can watch when it's done.
        The file you create will contain the whole movie edited.
        It takes quite awhile maybe 2 hours.  Sometimes the progress bar will look paused--it typically continues eventually.
      EOL
      @create.on_clicked {
        do_create_edited_copy_via_file false
      }
      
      @watch_file_edl = new_jbutton( "Watch movie file edited (realtime)" ) do
        choose_file_and_edl_and_create_sxs_or_play false 
      end
      
      if LocalStorage[UpConvertEnglish]
        add_text_line ''
        add_open_documentation_button
        @upconv_line = add_text_line "    #{get_current_upconvert_as_phrase}"
      else
        @upconv_line = add_text_line ''
        add_open_documentation_button
      end
      
      add_change_upconvert_options_button
      
      @progress_bar = JProgressBar.new(0, 100)
      @progress_bar.set_bounds(44,@starting_button_y,@button_width,23)
      @progress_bar.visible = false
      @panel.add @progress_bar

    end
    
    def add_open_documentation_button
      @open_help_file = new_jbutton("View Sensible Cinema Documentation") do
        show_in_explorer __DIR__ + "/../documentation" # TODO mac :)
      end
    end
    
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
        play_mplayer_edl_non_blocking [filename_mpg, edl_filename]
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
      
        @upload = new_jbutton("Submit Feedback/Upload new EDL's/Request Help") # keeps this one last! :)
        @upload.tool_tip = "We welcome all feedback!\nQuestion, comments, request help.\nAlso if you create a new EDL, please submit it back to us so that others can benefit from it later!"
        @upload.on_clicked {
          system_non_blocking("start mailto:sensible-cinema@googlegroups.com")
          system_non_blocking("start http://groups.google.com/group/sensible-cinema")
        }
        increment_button_location

      end
      
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

    def repeat_last_copy_dvd_to_hard_drive
      generate_and_run_bat_file *LocalStorage['last_params']
    end

    def parse_edl path
      EdlParser.parse_file path
    end
    def get_freespace path
      JFile.new(File.dirname(path)).get_usable_space
    end

    def choose_dvd_or_file_and_edl_for_it force_choose_edl_file_if_no_easy_match = true
      drive_or_file, dvd_volume_name, dvd_id = choose_dvd_drive_or_file false
      
      unless @_edit_list_path # cache file selection...
        edit_list_path = EdlParser.single_edit_list_matches_dvd(dvd_id)
        if !edit_list_path && force_choose_edl_file_if_no_easy_match
          edit_list_path = new_existing_file_selector_and_select_file("Please pick a DVD Edit List File (none or more than one were found that seem to match #{dvd_volume_name})--may need to create one for it", EdlParser::EDL_DIR)
          raise 'cancelled choosing an EDL' unless edit_list_path
        end
        @_edit_list_path = edit_list_path
      end
      
      if @_edit_list_path
        # reload it every time just in case it has changed on disk
        descriptors = nil
        while(!descriptors)
          begin
            descriptors = parse_edl @_edit_list_path
          rescue SyntaxError => e
            puts e
            show_blocking_message_dialog("this file has an error--please fix then hit ok: \n" + @_edit_list_path + "\n " + e)
          end
        end
      end
      [drive_or_file, dvd_volume_name, dvd_id, @_edit_list_path, descriptors]
    end
    
    def get_title_track descriptors, use_default_of_one = true
      given = descriptors["dvd_title_track"] 
      given ||= "1" if use_default_of_one
      given
    end
    
    def get_grabbed_equivalent_filename_once dvd_title, dvd_title_track
      @_get_grabbed_equivalent_filename_once ||=
      begin
        new_existing_file_selector_and_select_file "Please choose the file that is your ripped equivalent of #{dvd_title} (title track #{dvd_title_track}) (.mpg or .ts--see file documentation/how_to_get_files_from_dvd.txt)"
      end
    end
    
    def get_save_to_filename dvd_title
      @_get_save_to_filename ||=
      begin
        fc = new_nonexisting_filechooser "Pick where to save #{dvd_title} edited version to"
        save_to_file_name = dvd_title + ' edited version'
        save_to_file_name = save_to_file_name.gsub(' ', '_').gsub( /\W/, '') + ".avi" # no punctuation or spaces for now, to not complicate...
        fc.set_file(get_drive_with_most_space_with_slash + save_to_file_name)
        save_to = fc.go
        raise 'no spaces allowed yet' if save_to =~ / /
        begin
          a = File.open(File.dirname(save_to) + "/test_file_to_see_if_we_have_permission_to_write_to_this_folder", "w")
          a.close
          File.delete a.path
        rescue Errno::EACCES => e
          show_blocking_message_dialog "unable to write to that directory, please pick again: " + e.to_s
          raise 'pick again!'
        end
        freespace = get_freespace(save_to)
        if freespace < 8_000_000_000
          show_blocking_message_dialog("Warning: there may not be enough space on the disk for #{save_to} 
          (depending on DVD size, you may need around 10G free--you have #{freespace/1_000_000_000}GB free).  Click OK to continue.")
        end
        save_to.gsub(/\.avi$/, '')
      end
    end

    def do_create_edited_copy_via_file should_prompt_for_start_and_end_times, exit_early_if_fulli_exists = false, watch_unedited = false
      drive_or_file, dvd_volume_name, dvd_id, edit_list_path, descriptors = choose_dvd_or_file_and_edl_for_it
      
      descriptors = parse_edl(edit_list_path)
      if watch_unedited
        # reset them
        descriptors['mutes'] = descriptors['blank_outs'] = []
      end
      
      # LODO allow for spaces in the save_to filename
      if should_prompt_for_start_and_end_times
        # only show this message once :)
        @show_block ||= show_blocking_message_dialog(<<-EOL, "Preview")
          Ok, let's preview just a portion of it. 
          Note that you'll want to preview a section that wholly includes a deleted section in it.
          For example, if it mutes from second 1 to second 10, you'll want to play from 00:00 to 00:12 or what not.
          Also note that the first time you preview a section of a video, it will take a long time (like an hour) as it sets up the entire video for processing.
          Subsequent previews will be faster, though, as long as you use the same filename, as it won't have to re-set it up for processing.
          Also note that if you change your edit list, you'll need to close, and restart the video to be able to see it with your new settings.
        EOL
        old_start = LocalStorage['start_time']
        start_time = get_user_input("At what point in the video would you like to start your preview? (like 01:00 for starting at 1 minute)", LocalStorage['start_time'])
        default_end = LocalStorage['end_time']
        if start_time and start_time != old_start
          default_end = EdlParser.translate_string_to_seconds(start_time) + 10
          default_end = EdlParser.translate_time_to_human_readable(default_end)
        end
        end_time = get_user_input("At what point in the video would you like to finish your preview? (like 02:00 for ending at the 2 minute mark)", default_end)
        unless start_time and end_time
          JOptionPane.showMessageDialog(nil, " Please choose start and end", "Failed", JOptionPane::ERROR_MESSAGE)
          return
        end
        LocalStorage['start_time'] = start_time
        LocalStorage['end_time'] = end_time
      end
      dvd_friendly_name = descriptors['name']
      unless dvd_friendly_name
        drive_or_file, dvd_volume_name, dvd_id, edit_list_path, descriptors = choose_dvd_or_file_and_edl_for_it
        descriptors = parse_edl(edit_list_path)
        raise 'no dvd name in EDL?' + edit_list_path + File.read(edit_list_path)
      end
      
      dvd_title_track = get_title_track(descriptors)
      if dvd_id == NonDvd
        file_from = drive_or_file
      else
        file_from = get_grabbed_equivalent_filename_once dvd_friendly_name, dvd_title_track # we don't even care about the drive letter anymore...
      end
      show_blocking_message_dialog("warning: file #{file_from} is not a .mpg or .ts file--it may not work properly all the way--if it's mkv and fails consider first converting to ts by using tsmuxer.") unless file_from =~ /\.(ts|mpg|mpeg)$/i
      save_to_edited = get_save_to_filename dvd_friendly_name
      fulli = MencoderWrapper.calculate_fulli_filename save_to_edited
      if exit_early_if_fulli_exists
        if fulli_dot_done_file_exists? save_to_edited
          return [true, fulli]
        end
        # make it create a dummy response file for us :)
        start_time = "00:00"
        end_time = "00:01"
      end
      should_run_mplayer = should_prompt_for_start_and_end_times || exit_early_if_fulli_exists
      require_deletion_entry = true unless watch_unedited
      generate_and_run_bat_file save_to_edited, edit_list_path, descriptors, file_from, dvd_friendly_name, start_time, end_time, dvd_title_track, should_run_mplayer, require_deletion_entry
      [false, fulli] # false means it's running in a background thread :P
    end

    def get_drive_with_most_space_with_slash
      DriveInfo.get_drive_with_most_space_with_slash
    end
    
    def fulli_dot_done_file_exists? save_to_edited
      fulli = MencoderWrapper.calculate_fulli_filename save_to_edited
      File.exist?(fulli + ".done") # stinky!
    end
    
    # to make it stubbable :)
    def get_mencoder_commands descriptors, file_from, save_to, start_time, end_time, dvd_title_track, require_deletion_entry
      delete_partials = true unless start_time # in case anybody wants to look really really close [?]
      MencoderWrapper.get_bat_commands descriptors, file_from, save_to, start_time, end_time, dvd_title_track, delete_partials, require_deletion_entry
    end

    def generate_and_run_bat_file save_to, edit_list_path, descriptors, file_from, dvd_title, start_time, end_time, dvd_title_track, run_mplayer, require_deletion_entry
      LocalStorage['last_params'] = [save_to, edit_list_path, descriptors, file_from, dvd_title, start_time, end_time, dvd_title_track, run_mplayer, require_deletion_entry]
      begin
        commands = get_mencoder_commands descriptors, file_from, save_to, start_time, end_time, dvd_title_track, require_deletion_entry
      rescue MencoderWrapper::TimingError => e
        show_blocking_message_dialog("Appears you chose a time frame with no deletion segment in it--please try again:" + e)
        return
      rescue Errno::EACCES => e
        show_blocking_message_dialog("Appears a file on the system is locked: perhaps you need to close down some instance of mplayer?" + e)
        return
      end
      temp_dir = Dir.tmpdir
      temp_file = temp_dir + '/vlc.temp.bat'
      File.write(temp_file, commands)
      popup_message = <<-EOL
        Applying #{File.basename edit_list_path} 
           to #{file_from} (#{dvd_title}).
        Copying to #{save_to}.
      EOL
      if !fulli_dot_done_file_exists?(save_to)
        popup_message += "This could take quite awhile (several hours), and will prompt you with a chime noise when it is done.\n
        You can close this window and minimize sensible cinema and continue using your computer while it runs in the background.\n"
      end
      
      if !start_time
        # assume a full run..
        popup_message += <<-EOL
          NB that the created file will be playable only with VLC (possibly also with smplayer), 
          but probably not with windows media player.
        EOL
      end
      
      popup = show_non_blocking_message_dialog(popup_message, "OK")

      # allow our popups to still be serviced while it is running
      @background_thread = Thread.new { run_batch_file_commands_and_use_output_somehow commands, save_to, file_from, run_mplayer }
      when_thread_done(@background_thread) { popup.dispose }
      # LODO warn if they will overwrite a file in the end...
    end
    
    attr_accessor :background_thread, :buttons

    def run_batch_file_commands_and_use_output_somehow batch_commands, save_to, file_from, run_mplayer_after_done
      @buttons.each{|b| b.set_enabled false}
      success = true
      lines = batch_commands.lines.to_a
      total_size = lines.length.to_f
      @progress_bar.visible=true
      @progress_bar.set_value(10) # start at 10% always, so they can see something.
      lines.each_with_index{|line, idx|
        if success
          puts "running #{line}"
          success = system_blocking(line, true)
          if !success
            puts "\n", 'line failed: ' + line + "\n" + '   see troubleshooting section in README.txt file! ignoring further processing commands...'
          end
        end
        @progress_bar.set_value(10 + idx/total_size*90)
      }
      @progress_bar.visible=false
      @buttons.each{|b| b.set_enabled true}
      if success
        saved_to = save_to + '.avi'
        if run_mplayer_after_done
          run_smplayer_non_blocking saved_to, nil, '', false, false
        else
          if File.exist?(saved_to) && (File.size(saved_to).to_f/File.size(file_from) < 0.5) # less than 50% size is suspicious...indeed...check if exists for unit tests.
            show_blocking_message_dialog("Warning: file size differs by more than 50%--it's possible that transcoding failed somehow")
          end            
          show_in_explorer saved_to
          PlayAudio.play(File.expand_path(File.dirname(__FILE__)) + "/../vendor/music.wav")
          msg =  "Done--you may now watch file\n #{saved_to}\n in VLC player (or possibly smplayer)"
          puts msg # for being able to tell it's done on the command line
          show_blocking_message_dialog msg
          show_in_explorer saved_to # and again, just for kicks [?]
        end
      else
        show_blocking_message_dialog("Failed--please examine console output and report back!\nAlso consult the documentation/troubleshooting file.", "Failed", JOptionPane::ERROR_MESSAGE)
      end
    end
    
        NonDvd = 'non dvd has no dvdid' # we need it for convenience, say you want to go through your indexed vids and convert them all?

    # returns e:\, volume_name, dvd_id
    # or full_path.mkv, filename, ''
    def choose_dvd_drive_or_file force_choose_only_dvd_drive
      opticals = DriveInfo.get_dvd_drives_as_openstruct
      if @saved_opticals == opticals && @_choose_dvd_drive_or_file
        # memoize...if disks haven't changed :)
        return @_choose_dvd_drive_or_file
      else
        @saved_opticals = opticals # save currently mounted disk list, so we know if we should re-select later... 
        # is this ok for os x?
      end

      has_at_least_one_dvd_inserted = opticals.find{|d| d.VolumeName }
      if !has_at_least_one_dvd_inserted && force_choose_only_dvd_drive
        show_blocking_message_dialog 'insert a dvd first' 
        raise 'no dvd found'
      end
      names = opticals.map{|d| d.Name + "\\" + " (" +  (d.VolumeName || 'Insert DVD to use') + ")"}
      if !force_choose_only_dvd_drive && !has_at_least_one_dvd_inserted
        names += ['No DVD mounted so choose Local File (or insert DVD, re-try)'] # LODO cannot read it...
        used_local_file_option = true
      end
      
      count = 0
      opticals.each{|d| count += 1 if d.VolumeName}
      if count == 1 && !used_local_file_option
       # just choose it if there's only one disk available..
       p 'selecting only disk present in the various DVD drives'
       selected_idx = opticals.index{|d| d.VolumeName}
       unless selected_idx
         show_blocking_message_dialog "Please insert a disk first"
         raise 'inset disk'
       end

      else
        dialog = get_disk_chooser_window names
        dialog.setSize 200, 125
        dialog.show
        selected_idx = dialog.selected_idx
      end
      
      if selected_idx
        if used_local_file_option
          raise unless selected_idx == 0 # it was our only option...
          filename = new_existing_file_selector_and_select_file("Select yer previously grabbed from DVD file")
          assert_ownership_dialog
          return [filename, File.basename(filename), NonDvd]
        else
          disk = opticals[selected_idx]
          out = show_non_blocking_message_dialog "calculating current disk's unique id...if this freezes clean your disk..." # useful, believe it or not
          dvd_id = DriveInfo.md5sum_disk(disk.MountPoint)
          out.dispose
          @_choose_dvd_drive_or_file = [disk.MountPoint, opticals[selected_idx].VolumeName, dvd_id]
          return @_choose_dvd_drive_or_file
        end
      else
        raise 'did not select a drive...'
      end
    end

    
  end
end

