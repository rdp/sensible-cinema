module SensibleSwing
  
  class MainWindow
    
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
        run_smplayer_blocking nice_file, nil, "-edl #{normalize_path EdlTempFile}", false, true, false
      }
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
        start_time, end_time = get_start_stop_times_strings
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
      if file_from =~ /\.mkv/i
        show_blocking_message_dialog "warning .mkv files from makemkv have been known to be off timing wise, please convert to a .ts file using tsmuxer first if it did come from makemkv"
      end
      if file_from !~ /\.(ts|mpg|mpeg)$/i
        show_blocking_message_dialog("warning: file #{file_from} is not a .mpg or .ts file--it may not work properly all the way, but we'll can try...") 
      end
      
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
      require_deletion_entry = true unless watch_unedited
      should_run_mplayer_after = should_prompt_for_start_and_end_times || exit_early_if_fulli_exists
      generate_and_run_bat_file save_to_edited, edit_list_path, descriptors, file_from, dvd_friendly_name, start_time, end_time, dvd_title_track, should_run_mplayer_after, require_deletion_entry
      [false, fulli] # false means it's running in a background thread :P
    end 
  end
end