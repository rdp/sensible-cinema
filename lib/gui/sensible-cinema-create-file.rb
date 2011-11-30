module SensibleSwing
  
  class MainWindow
    
    def add_options_that_use_local_files
	  check_for_file_manipulation_dependencies
      add_text_line 'These are Create Options that operate on a file:'

      @preview_section = new_jbutton( "Preview a certain time frame (edited)" )
      @preview_section.tool_tip = <<-EOL
        This allows you to preview an edit easily.
        It is the equivalent of saying \"watch this file edited from exactly minute x second y to minute z second q"
        Typically if you want to test an edit, you can start a few seconds before, and end a few seconds after it, to test it precisely.
      EOL
      @preview_section.on_clicked {
        do_create_edited_copy_via_file true
      }
      
      @preview_section_unedited = new_jbutton("Preview a certain time frame (unedited)" )
      @preview_section.tool_tip = "Allows you to view a certain time frame unedited (ex: 10:00 to 10:05), so you can narrow down to pinpoint where questionable scenes are, etc. This is the only way to view a specific scene if there are not cuts within that scene yet."
      @preview_section_unedited.on_clicked {
        do_create_edited_copy_via_file true, false, true
      }

      @rerun_preview = new_jbutton( "Re-run most recently watched previewed time frame" )
      @rerun_preview.tool_tip = "This will re-run the preview that you most recently performed.  Great for checking to see if you last edits were successful or not."
      @rerun_preview.on_clicked {
        repeat_last_copy_dvd_to_hard_drive
      }
      
      # I think this is still useful...
      @fast_preview = new_jbutton("fast preview EDL from fulli file (smplayer EDL)")
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
      
      dvd_title_track = get_title_track_string(descriptors)
      if dvd_id == NonDvd
        file_from = drive_or_file
      else
        file_from = get_ripped_filename_once dvd_friendly_name, dvd_title_track # we don't even care about the drive letter anymore...
      end
      
      sanity_check_file file_from
      
      save_to_edited = get_save_to_filename_from_user dvd_friendly_name
      fulli = MencoderWrapper.calculate_fulli_filename save_to_edited
      if exit_early_if_fulli_exists
        if fulli_dot_done_file_exists? save_to_edited
          return [true, fulli]
        end
        # make it create a dummy response file for us :)
        start_time = "00:00"
        end_time = "00:01"
      end
      
      if !fulli_dot_done_file_exists? save_to_edited
        show_non_blocking_message_dialog "Warning, the first pass through when editing file-wise, Sensible Cinema\nfirst needs to create a large temporary file that it can divide up easily.\nThis takes awhile, so you may need to get comfortable."
      end

      require_deletion_entry = true unless watch_unedited
      should_run_mplayer_after = should_prompt_for_start_and_end_times || exit_early_if_fulli_exists
      generate_and_run_bat_file save_to_edited, edit_list_path, descriptors, file_from, dvd_friendly_name, start_time, end_time, dvd_title_track, should_run_mplayer_after, require_deletion_entry
      [false, fulli] # false means it's running in a background thread :P
    end 
    
    def sanity_check_file filename
      out = `ffmpeg -i #{filename} 2>&1`
      print out
      unless out =~ /Duration.*start: 0.00/ || out =~ /Duration.*start: 600/
        show_blocking_message_dialog 'file\'s typically have the movie start at zero, this one doesn\'t? Please report.' + out
        raise # give up, as otherwise we're 0.3 off, I think...hmm...
      end
      if filename =~ /\.mkv/i
        show_blocking_message_dialog "warning .mkv files from makemkv have been known to be off timing wise, please convert to a .ts file using tsmuxer first if it did come from makemkv"
      else
        if filename !~ /\.(ts|mpg|mpeg)$/i
          show_blocking_message_dialog("warning: file #{filename} is not a .mpg or .ts file--conversion may not work properly all the way [produce a truncated file], but we can try it if you want...") 
        end
      end
    end
    
    def repeat_last_copy_dvd_to_hard_drive
      generate_and_run_bat_file *LocalStorage['last_params']
    end

    def get_ripped_filename_once dvd_title, dvd_title_track
      @_get_ripped_filename_once ||=
      begin
        new_existing_file_selector_and_select_file "Please choose the file that is your ripped equivalent of #{dvd_title} (title track #{dvd_title_track}) (.mpg or .ts--see file documentation/how_to_get_files_from_dvd.txt)"
      end
    end
    
    def get_save_to_filename_from_user dvd_title
      @_get_save_to_filename_from_user ||=
      begin
        save_to_file_name = dvd_title + ' edited version'
        save_to_file_name = save_to_file_name.gsub(' ', '_').gsub( /\W/, '') + ".avi" # no punctuation or spaces for now, to not complicate...
        save_to = new_nonexisting_filechooser_and_go "Pick where to save #{dvd_title} edited version to", nil, get_drive_with_most_space_with_slash + save_to_file_name
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
    
    def fulli_dot_done_file_exists? save_to_edited
      fulli = MencoderWrapper.calculate_fulli_filename save_to_edited
      File.exist?(fulli + ".done")
    end
    
    # to make it stubbable :)
    def get_mencoder_commands descriptors, file_from, save_to, start_time, end_time, dvd_title_track, require_deletion_entry
      delete_partials = true unless start_time # in case anybody wants to look really really close for now
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
        Applying EDL #{File.basename edit_list_path} 
           to movie file #{file_from} (#{dvd_title}).
        Saving to #{save_to}.
      EOL
      if !fulli_dot_done_file_exists?(save_to)
        popup_message += "This will take quite awhile (several hours, depending on movie size), \nsince it needs to first create an intermediate file for more accurate splitting.\nit will prompt you with a chime noise when it is done.\n
        You can close this window and minimize sensible cinema \nto continue using your computer while it runs in the background.\nYou can see progress via the progress bar.\n"
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
          run_smplayer_non_blocking saved_to, nil, '', false, false, true
        else
          size_original = File.size(file_from)
          size_edited_version = File.size(saved_to)
          if size_edited_version < (size_original*0.5)
            show_blocking_message_dialog("Warning: file sizes differs by more than 50%--it's possible that transcoding failed somehow. Orig: #{size_original} edited: #{size_edited_version}")
          end
          show_in_explorer saved_to
          PlayAudio.new(File.expand_path(File.dirname(__FILE__)) + "/../../vendor/music.wav").start # let it finish on its own :P
          msg =  "Done--you may now watch file\n #{saved_to}\n in VLC player (or possibly smplayer)"
          puts msg # for being able to tell it's done on the command line
          show_blocking_message_dialog msg
        end
      else
        SwingHelpers.show_blocking_message_dialog "Failed--please examine console output and report back!\nAlso consult the documentation/troubleshooting file.", "Failed", JOptionPane::ERROR_MESSAGE
      end
    end
    
    
    
  end
end
