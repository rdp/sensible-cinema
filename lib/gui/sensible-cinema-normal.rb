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
          run_smplayer_non_blocking saved_to, nil, '', false, false, true
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
        SwingHelpers.show_blocking_message_dialog "Failed--please examine console output and report back!\nAlso consult the documentation/troubleshooting file.", "Failed", JOptionPane::ERROR_MESSAGE
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
          out = show_non_blocking_message_dialog "calculating current disk's unique id...if this pauses more than 10s then clean your DVD..."
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

