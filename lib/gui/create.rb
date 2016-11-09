module SensibleSwing
  
  class MainWindow

    def open_edl_file_when_done thred, filename
      Thread.new {
        thred.join
        open_file_to_edit_it filename
      }
    end

    def setup_create_buttons
	  # only create mode needs this uh guess
      EdlParser.on_any_file_changed_single_cached_thread { DriveInfo.notify_all_drive_blocks_that_change_has_occured }
	  
	    add_text_line 'Normal playback Options:'
      new_jbutton("Display Normal Playback Options") do
        window = new_child_window
        window.setup_normal_buttons
      end
      
      add_text_line 'Create: Edit Decision List File Options:'
      
      @open_current = new_jbutton("Edit/Open EDL for currently inserted DVD") do
        drive, volume_name, dvd_id = choose_dvd_drive_or_file true # require a real DVD disk :)
        edit_list_path = EdlParser.single_edit_list_matches_dvd(dvd_id)
        if edit_list_path
          open_file_to_edit_it edit_list_path
        else
          show_blocking_message_dialog "EDL for this dvd doesn't exist yet, maybe create it first? #{volume_name}"
        end
      end
      
      create_new_edl_for_current_dvd_text = "Create new Edit List for currently inserted DVD"
      @create_new_edl_for_current_dvd = new_jbutton(create_new_edl_for_current_dvd_text, 
          "If your DVD doesn't have an EDL created for it, this will be your first step--create an EDL file for it.")
      @create_new_edl_for_current_dvd.on_clicked do
  	    drive, volume_name, dvd_id = choose_dvd_drive_or_file true # require a real DVD disk :)
        edit_list_path = EdlParser.single_edit_list_matches_dvd(dvd_id, true)
        if edit_list_path
		    if show_select_buttons_prompt('It appears that one or more EDL\'s exist for this DVD already--create another?', {}) == :no
		        raise 'aborted'
		    end
        end	  
        create_brand_new_dvd_edl
        show_blocking_message_dialog "Now that it's created, you can add some entries by hand, or try parsing subtitles to detect profanities (\"scan a subtitle\" button)"
      end
      
      add_callback_for_dvd_edl_present { |disk_available, edl_available|
        #TODO rdp file buttons
        @open_current.set_enabled edl_available
        #@create_new_edl_for_current_dvd.set_enabled disk_available
        if edl_available
          @create_new_edl_for_current_dvd.text= create_new_edl_for_current_dvd_text + " [yours already has one!]"
        else
		  if disk_available
            @create_new_edl_for_current_dvd.text= create_new_edl_for_current_dvd_text + " [it doesn't have one yet!]"
		  else
		    @create_new_edl_for_current_dvd.text= create_new_edl_for_current_dvd_text + " [no disk inserted!]"
		  end
        end
      }
      
      @parse_srt = new_jbutton("Scan a subtitle file to detect profanity timestamps automatically" )
      @parse_srt.tool_tip = <<-EOL
        You can download a .srt file and use it to programmatically search for the location of various profanities.
        Basically download it from opensubtitles.org 
        (or google search for something like your equivalent for "prince of egypt subtitles 1cd en",
        (for opensubtitles.org enter dvd title in the search box, click on a result, click one from the list with an English flag, 
        then choose 'Download(zip)', then unzip the file)
        NB that you'll want/need to *carefully* double check your subtitle file for accuracy. Here's how:
        Now carefully compare a beginning timestamp in it with the actual words in the .srt file 
        with the actual DVD.
        (see the button "Watch DVD unedited (realtime mplayer)")
        (smplayer can kind of do it, too, play it, hit the 'o' button to display
        the OSD timestamp, then go to just before the verbiage, 
        and hit the '.' key until a subtitle very first appears.
        Next convert that number to 29.97 fps (using the button for that).
      EOL

      @parse_srt.on_clicked do

        srt_filename = new_existing_file_selector_and_select_file("Pick srt file to scan for profanities [may need to download .srt file first]:", File.expand_path('~'))
		    if(srt_filename =~ /utf16/) # from subrip sometimes
		      show_blocking_message_dialog "warning--filename #{srt_filename} may be in utf16, which we don't yet parse"
                    end
		if srt_filename =~ /\.sub$/i
		  show_blocking_message_dialog "warning--input file has to be in SubRip [.srt] format, and yours might be in .sub format, which is incompatible"
		end
 
        euphemized_entries = euphemized_filename = nil
        with_autoclose_message("parsing srt file... #{File.basename srt_filename}") do
          begin
		    parsed_profanities, euphemized_entries = SubtitleProfanityFinder.edl_output_from_string File.read(srt_filename), {},  0, 0, 0, 0, 3000, 3000
            write_subs_to_file euphemized_filename = get_temp_file_name('euphemized.nonsynchronized.subtitles.srt.txt'), euphemized_entries
		  rescue => e
		    show_blocking_message_dialog "unable to parse #{srt_filename}\n#{e}?"
			raise
		  end
        end

	if show_select_buttons_prompt("Sometimes subtitle files' time signatures don't match precisely with the video.\nWould you like to enter some information to allow it to synchronize the timestamps?\n  (on the final pass you should do this, even if it already matches well, for future information' sake)") == :yes

          if show_select_buttons_prompt("Would you like to start playing the movie in smplayer, to be able to search for subtitle timestamp timings?") == :yes
            show_blocking_message_dialog "ok--use the '.' key and on your keyboard to pinpoint a precise subtitle start time within mplayer.
Use arrow keys to seek.
You will be prompted for a beginning and starting timestamp time to search for.\nIt may take a few seconds for the player to appear..."
            play_dvd_smplayer_unedited false
          end

  	      open_file_to_edit_it euphemized_filename
          sleep 0.5 # let it open in TextEdit/Notepad first...
      	  bring_to_front

          all_entries = euphemized_entries # rename :)
          start_entry = all_entries[0]
          start_text = start_entry.single_line_text
          start_srt_time = start_entry.beginning_time
          human_start = EdlParser.translate_time_to_human_readable(start_srt_time)
          start_movie_sig = get_user_input_with_persistence("Enter beginning timestamp within the movie itself for when the subtitle \"#{start_text}\"\nfirst frame the subtitle appears on the on screen display (possibly near #{human_start})", start_text)
          start_movie_time = EdlParser.translate_string_to_seconds start_movie_sig
          if(show_select_buttons_prompt 'Would you like to select an ending timestamp at the end or 3/4 mark of the movie [end can be a spoiler at times]?', :yes => 'very end of movie', :no => '3/4 of the way into movie') == :yes
           end_entry = all_entries[-1]
          else
           end_entry = all_entries[all_entries.length*0.75] 
          end
          end_text = end_entry.single_line_text
          end_srt_time = end_entry.beginning_time
          human_end = EdlParser.translate_time_to_human_readable(end_srt_time)
          end_movie_sig = get_user_input_with_persistence("Enter beginning timestamp within the movie itself for when the subtitle ##{end_entry.index_number}\n\"#{end_text}\"\nfirst appears (possibly near #{human_end}).\nYou can find it by searching to near that time in the movie [pgup+pgdown, then arrow keys], find some subtitle, then find where that subtitle is within the .srt file to see where it lies\nrelative to the one you are interested in\nthen seek relative to that to find the one you want.", end_text) 
		  end_movie_time = EdlParser.translate_string_to_seconds end_movie_sig
        else
          # the case they know it already matches
	  start_srt_time = 0
          start_movie_time = 0
          end_srt_time = 3000
          end_movie_time = 3000
    	end

        parsed_profanities, euphemized_synchronized_entries = nil
		extra_profanity_hash = {}
		if LocalStorage['prompt_obscure_options']
		  got = get_user_input_with_persistence("enter any 'extra' words to search for, like badword1,badword2 if any", srt_filename + 'words', true)
		  if got
		    for entry in got.split(',')
		      extra_profanity_hash[entry] = entry
		    end
		  end
		end

        with_autoclose_message("parsing srt file... #{File.basename srt_filename}") do
          parsed_profanities, euphemized_synchronized_entries = SubtitleProfanityFinder.edl_output_from_string File.read(srt_filename), extra_profanity_hash, 0.0, 0.0, start_srt_time, start_movie_time, end_srt_time, end_movie_time
        end
		
        middle_entry = euphemized_synchronized_entries[euphemized_synchronized_entries.length*0.5]
        show_blocking_message_dialog "You may want to double check if the math worked out and if the adjusted subtitles now match the movie.\n\"#{middle_entry.single_line_text}\" (##{middle_entry.index_number})\nshould appear at #{EdlParser.translate_time_to_human_readable middle_entry.beginning_time} (not accomodating for added start times)\nYou can go and check it!\nIf it's off much you may want to try this whole process again\n with a different other .srt file"		
        # LODO ask them if it worked... [?]
		
		if end_srt_time != 3000
		  add_to_beginning_all = get_user_input("Would you like to adjust all subtitles and make them start any seconds earlier (like 1.0)?", "0.0").to_f
		  add_to_end_all = get_user_input("Would you like to adjust all subtitles and make them all end any seconds later (like 1.0)?", "0.0").to_f
		else
		  add_to_beginning_all=0.0
		  add_to_end_all=0.0
		end

        with_autoclose_message("parsing srt file... #{File.basename srt_filename}") do
          parsed_profanities, euphemized_synchronized_entries = SubtitleProfanityFinder.edl_output_from_string File.read(srt_filename), extra_profanity_hash, add_to_beginning_all, add_to_end_all, start_srt_time, start_movie_time, end_srt_time, end_movie_time
        end		
        
        filename = get_temp_file_name('mutes.edl.txt')
		if parsed_profanities.present?
          out =  "# copy and paste these into your \"mute\" section of A SEPARATE EDL already created with the other buttons, for lines you deem mute-worthy\n" + parsed_profanities
		else
		  out = "# no mute-worthy profanities found..."
		end
        if end_srt_time != 3000
		  out += %!\n\n#Also add these lines at the bottom of the EDL (for later coordination):\n"beginning_subtitle" => ["#{start_text}", "#{start_movie_sig}", #{start_entry.index_number}],! +
               %!\n"ending_subtitle_entry" => ["#{end_text}", "#{end_movie_sig}", #{end_entry.index_number}],\n!
	    end
		
		File.write filename, out.gsub("\n", "\r\n") # notepad friendly ai ai
        open_file_to_edit_it filename
        sleep 1 # let it open in notepad
		
		write_subs_to_file get_temp_file_name('euphemized.synchronized.edl.txt'), euphemized_synchronized_entries
		
		if LocalStorage['prompt_obscure_options']
	      if show_select_buttons_prompt("Would you like to write out a synchronized, euphemized .srt file [useful if you want to watch the movie with sanitized subtitles later]\nyou probably don't?") == :yes
            out_file = new_nonexisting_filechooser_and_go("Select filename to write to", File.dirname(srt_filename), File.basename(srt_filename)[0..-5] + ".euphemized.srt")
		    write_subs_to_file out_file, euphemized_synchronized_entries
            show_in_explorer out_file
          end		  
		end
        
      end
	  
      add_text_line 'Create: Advanced View Edited Options'
      
      @mplayer_edl_with_subs = new_jbutton( "Watch DVD edited (realtime) (with mplayer, subtitles)") do
        watch_dvd_edited_realtime_mplayer true
      end
      
	  @mplayer_edl_with_subs.tool_tip="This watches it in mplayer, which has access to its console output, and also includes subtitles."
	  
      @mplayer_partial = new_jbutton( "Watch DVD edited (realtime) (mplayer) based on timestamp") do
        times = get_start_stop_times_strings
        times.map!{|t| EdlParser.translate_string_to_seconds t}
        start_time = times[0]
        end_time = times[1]
        extra_mplayer_commands = ["-ss #{start_time}", "-endpos #{end_time - start_time}"]
        play_smplayer_edl_non_blocking nil, extra_mplayer_commands, true, false, add_end = 0.0, add_begin = 0.0 # create mode => aggressive
      end
	  
	  @mplayer_partial.tool_tip="this can play just a specific portion of your film, like from second 30 to 35, for testing."

      # all OS's apparently still use mplayer raw in an advanced edit mode or other? huh wuh?
      new_jbutton("Display mplayer keyboard commands/howto/instructions") do
        show_mplayer_instructions
      end

      add_text_line "Create: Watch Unedited Options:"
      
      @play_smplayer = new_jbutton( "Watch DVD unedited (realtime smplayer)")
      @play_smplayer.tool_tip = <<-EOL
        This will play the DVD unedited within smplayer.
        NB it will default to title 1, so updated your EDL file that matches this DVD with the proper title if this doesn't work for you 
        i.e. if it just plays a single preview title or what not, and not the main title, you need to change this value.
        This is useful if you want to just kind of watch the movie to enjoy it, and look for scenes to cut out.
        You can use the built-in OSD (on-screen-display) to see what time frame the questionable scenes are at
        (type "o" to toggle it).  However, just realize that the OSD is in 30 fps, and our time stamps are all in 29.97
        fps, so you'll need to convert it (the convert timestamp button) to be able to use it in a file.
        NB That you can get the mplayer keyboard control instructions with the show instructions button.
      EOL
      @play_smplayer.on_clicked {
        play_dvd_smplayer_unedited false
      }

      new_jbutton("Create new Edit List (for netflix instant or for a local file)") do # LODO VIDEO_TS here too?
	    create_new_for_file_or_netflix
      end

	  
      @display_dvd_info = new_jbutton( "Display information about current DVD (ID, timing, etc.)" )
      @display_dvd_info.tool_tip = "This is useful to setup a DVD's 'unique ID' within an EDL for it. \nIf your EDL doesn't have a line like disk_unique_id => \"...\" then you will want to run this to be able to add that line in."
      @display_dvd_info.on_clicked {
        Thread.new {
          out_hashes, raw_title_lengths = get_disk_info
	      out_string = out_hashes.map{|name, value| name.inspect + ' => ' + value.inspect  + ','}.join("\n") + "\n" + raw_title_lengths.map{|raw| "#" + raw}.join("\n")
          out_string += %!\n"timestamps_relative_to" => ["file", "29.97"],! # we do our best to emulate it these days :)
          filename = get_temp_file_name('disk_info.txt')
          File.write filename, out_string 
          open_file_to_edit_it filename
          out_string # for unit tests--do I still need this?
        }
      }
      
      
      add_text_line "Less commonly used Edit options:"

      new_jbutton("Show more (rarely used) buttons/options") do
        child = new_child_window
        child.show_rarely_used_buttons
      end

    end

		def write_subs_to_file out_file, euphemized_synchronized_entries
          File.open(out_file, 'wb') do |f|
            euphemized_synchronized_entries.each_with_index{|entry, idx|
              beginning_time = EdlParser.translate_time_to_human_readable(entry.beginning_time, true).gsub('.',',')
              ending_time = EdlParser.translate_time_to_human_readable(entry.ending_time, true).gsub('.',',')
              f.print entry.index_number
              f.print "\r\n" # jruby bug that puts doesn't do this right with permissions 'w' ?
              f.print "#{beginning_time} --> #{ending_time}"
              f.print "\r\n"
              f.print entry.text
              f.print "\r\n"
              f.print "\r\n"
            }
		  end
	    end
	
    def show_rarely_used_buttons
      if we_are_in_developer_mode?
       @reload = new_jbutton("[programmer mode] reload bin/sensible-cinema code") do
         for file in Dir[__DIR__ + '/*.rb']
           p file
           eval(File.read(file), TOPLEVEL_BINDING, file)
         end
       end
      end

      @convert_seconds_to_ts = new_jbutton( "Convert 3600.0 <-> 1:00:00 style timestamps" )
      @convert_seconds_to_ts.on_clicked {
        input = get_user_input("Enter \"from\" timestamp, like 3600 or 1:40:00:", "1:00:00.1 or 3600.1")
        while(input)
          if input =~ /:/
            output = EdlParser.translate_string_to_seconds input
            output = "%.02f" % output # so they know we're not rounding for example 6.10 not 6.1
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
        smplayer's on-screen-display (the 'o' key) is accurate (and doesn't suffer from MPEG timestamps resets midway through) 
        but is 30 fps, so timestamps would need to be converted.
        Dont use VLC for DVD timestamps at all--it can get up to 30s off!  VLC playing back a file is usually pretty accurate to 29.97.
        In general, GUI's like VLC or smplayer are always a tidge off (maybe 0.3s) from the right timestamp, so take that into consideration.
        Mplayers "V: 3600" is usually right on (29.97 fps), however.
      EOL
      @convert_timestamp.on_clicked {
        thirty_fps = get_user_input("Enter your DVD/hardware (30 fps) timestamp, I'll convert it to 29.97 (usable in EDL's):", "1:00:00.1")
        thirty_fps_in_seconds = EdlParser.translate_string_to_seconds thirty_fps
        twenty_nine_seven_fps = ConvertThirtyFps.from_thirty(thirty_fps_in_seconds)
        human_twenty_nine_seven = EdlParser.translate_time_to_human_readable twenty_nine_seven_fps, true
        show_copy_pastable_string("Sensible cinema usable value (29.97 fps) for #{thirty_fps} would be:                ", human_twenty_nine_seven)
      }
      
      @create_dot_edl = new_jbutton( "Create a side-by-side moviefilename.edl file [XBMC use, etc.]")
      @create_dot_edl.tool_tip = <<-EOL
        Creates a moviefilename.edl file (corresponding to some moviefilename.some_ext file already existing)
        XBMC/smplayer (smplayer can be used by WMC plugins, etc.) "automagically detect", 
        if it exists, and automatically use it .edl to show that file edited played back.
        If you use smplayer, note that you'll need to download the "lord mulder mplayer"
        version (which includes an updated version of mplayer that fixes some bugs in EDL playback)
      EOL
      @create_dot_edl.on_clicked {
        show_blocking_message_dialog "Warning: With XBMC you'll need at least Eden v11.0 for mutes to work at all"
        choose_file_and_edl_and_create_sxs_or_play true
      }
	  
	  new_jbutton("open arbitrary file to edit it") do
	    path = SimpleGuiCreator.new_previously_existing_file_selector_and_go "Select file to open/edit"
		open_file_to_edit_it path
	  end
	  
	  
      @upconvert_screen = new_jbutton( "play screen upconverted" )
      @upconvert_screen.on_clicked {
        program_files_dir = ENV['ProgramFiles'].gsub("\\", '/')
        if Dir[program_files_dir  +"/AviSynth*"].empty? # allow different versions of it...
		  show_blocking_message_dialog "warning, you may need/want to install avisynth first!"
		end
        if !File.directory?(program_files_dir  + "/Screen Capturer Recorder")
		  show_blocking_message_dialog "warning, you may need/want to install the screen capture recorder package first!"
		end
		show_blocking_message_dialog "To get this to work, first start your video playing [windows--not full screen].\n  Then run the screen capture recorder's \"configure by resizing a transparent window\" utility, cover the movie part of the player wiht it, and hit ok.  Then click ok here..."
        # what fps is this?
        # maybe should enable...dedupe?
		system("#{mplayer_local} -benchmark -geometry 10:10 upconvert_from_screen\\upconvert_from_screen_me2.avs") # I am not in the "bin" directory...
      }
	  
      if LocalStorage['have_zoom_button']
        @create_zoomplayer = new_jbutton( "Create a ZoomPlayer MAX compatible EDL file") do
          raise unless OS.doze?
          @prompt ||= show_blocking_message_dialog <<-EOL
  To work with ZoomPlayer MAX's scene cut functionality, first play the DVD you want to watch edited, and 
  create a dummy cut for it in it via the ZoomPlayer MAX cut scene editor. (right click -> open interface -> scene cut editor)
  Once you create a cut, ZoomPlayer will create a file like this:
  [windows 7]: c:\\Users\\All Users\\Zoom Player\\DVD-Bookmarks\\Sintel_NTSC.3D4D1DFBEB1A53FE\\disc.cut
  
  After it has been created, come back to this.  You will next be prompted to select the generated disc.cut file, and also a sensible cinema EDL file.
  The generated file will then be overwritten with the sensible cinema EDL information.
  DVD compatible only currently--ask if you want it for file based selection as well and I can add it.
          EOL
          zoom_path  = new_existing_file_selector_and_select_file( "Pick Zoomplayer disc.cut File to override", ENV["ALLUSERSPROFILE"]+ '/Zoom Player/DVD-Bookmarks' )
          edl_path = new_existing_file_selector_and_select_file( "Pick EDL", EdlParser::EDL_DIR)
          specs = parse_edl(edl_path)
          require_relative '../zoom_player_max_edl'
          out = ZoomPlayerMaxEdl.convert_to_edl_string specs
          File.write(zoom_path, out)
          show_blocking_message_dialog "wrote #{zoom_path}"
        end
      end
    end
    
    def get_disk_info
	    drive, volume_name, dvd_id = choose_dvd_drive_or_file true # require a real DVD disk :)
      # display it, allow them to copy and paste it out
	    out_hashes = {}
	    out_hashes['disk_unique_id'] = dvd_id
	    out_hashes['volume_name'] = volume_name
      popup = show_non_blocking_message_dialog "calculating DVD title sizes..."
      command = "#{mplayer_local} -vo direct3d dvdnav:// -nocache -dvd-device #{drive} -identify -frames 0 2>&1"
      puts command
      title_lengths_output = `#{command}`
      popup.close
      edit_list_path = EdlParser.single_edit_list_matches_dvd(dvd_id)
      if edit_list_path
    	  parsed = parse_edl edit_list_path
        title_to_get_offset_of = get_title_track_string(parsed)
      else
        title_to_get_offset_of = nil
      end
      raw_title_lengths = title_lengths_output.split("\n").select{|line| line =~ /ID_DVD_TITLE_.*LENGTH/}
      # ID_DVD_TITLE_4_LENGTH=365.000
      titles_with_length = raw_title_lengths.map{|name| name =~ /ID_DVD_TITLE_(\d+)_LENGTH=([\d\.]+)/; [$1, $2.to_f]}
	  if titles_with_length.length > 50
	    show_blocking_message_dialog "this DVD has > 50 titles, this may mean that our 'guess' for the main title will be off, please double check the right number\nby starting the main movie in VLC then Playback menu -> title to see which number it is on."
	  end
      largest_title = titles_with_length.max_by{|title, length| length}
  	  if !largest_title
  	    display_and_raise "unable to parse title lengths? maybe need to clean disk first? #{title_lengths_output}"
	  end
	    largest_title = largest_title[0]
      title_to_get_offset_of ||= largest_title
 	    out_hashes['dvd_title_track'] = title_to_get_offset_of
	    out_hashes['dvd_title_track_length'] = titles_with_length.detect{|title, length| title == title_to_get_offset_of}[1]
      offsets = calculate_dvd_start_offset(title_to_get_offset_of, drive)
    	start_offset = offsets[:mpeg_start_offset]
	    out_hashes['dvd_title_track_start_offset'] = start_offset
      out_hashes['dvd_nav_packet_offset'] = offsets[:dvd_nav_packet_offset]
	    [out_hashes, raw_title_lengths]
    end
	
    def watch_dvd_edited_realtime_mplayer show_subs
      edl_out_command = ""
      if LocalStorage['prompt_obscure_options']
        answer = show_select_buttons_prompt <<-EOL, {}
          Would you like to create an .edl outfile as it plays (hit button to capture timestamps)?
          EOL
        if answer == :yes
          show_non_blocking_message_dialog <<-EOL
          EDL outfile:
          As mplayer goes through the video, when you see a scene you want to edit or skip, 
          hit 'i' and mplayer will write the start time in the file and set it to skip for 2 seconds, 
          hit 'i' again to end the edited/skipped scene, within that file.
          EOL
  
          edlout_filename = new_nonexisting_filechooser_and_go "pick edlout filename"
          edl_out_command = "-edlout #{edlout_filename}"
          
        else
          @has_ever_rejected_edl_outfile = true
        end
      end
      thred = play_smplayer_edl_non_blocking nil, [edl_out_command], (force_mplayer = true), false, add_end = 0.0, add_begin = 0.0, show_subs # more aggressive :)
      if(edl_out_command.present?)
        open_edl_file_when_done thred, edlout_filename
      end
    end
    
    def calculate_dvd_start_offset title, drive
      popup = show_non_blocking_message_dialog "calculating start info for title #{title}..." # must be non blocking so the command can run :P
      command = "#{mplayer_local} -benchmark -frames 35  -osd-verbose -osdlevel 2 -vo null -nosound dvdnav://#{title} -nocache -dvd-device #{drive}  2>&1"
      puts command
      out = `#{command}`
      #search for V:  0.37
      popup.close
      outs = {}
	  old_mpeg = 0
      out.each_line{|l|
        if l =~  /V:\s+([\d\.]+)/
          outs[:mpeg_start_offset] ||= $1.to_f
        end
	    float = /\d+\.\d+/
	    if l =~ /last NAV packet was (#{float}), mpeg at (#{float})/
          nav = $1.to_f
          mpeg = $2.to_f
          if !outs[:dvd_nav_packet_offset] && nav > 0.0 && mpeg > 0.04 # we hit our first real "NAV" packet, like 0.4
			  if mpeg < (nav - 0.05) # 0.05 for karate kid. weird.
			    # case there is an MPEG split before the second NAV packet [ratatouille, hp] or does it only occur right *at* the first nav?
			    p mpeg, nav, old_mpeg
				# works with ...=c=
				# TODO incredibles...
				mpeg = old_mpeg + mpeg - 0.033367 # assume 30 fps, and that this is the second frame since it occurred, since the first one we apparently display "weird suddenly we're not a dvd?"
				show_blocking_message_dialog "this dvd has some weird timing stuff at the start, attempting to accomodate...please report to the mailing list...\nyou may want to double check the math..."
				puts out # so they can manually debug it if they so desire LOL.
			    # assert old_mpeg > 0.3
			  end
	          outs[:dvd_nav_packet_offset] = [nav, mpeg] # like [0.4, 0.6] or the like
          else
			  old_mpeg = mpeg # ratatouile weirdness...TODO FIX ME
	      end
      	end
      }
      show_blocking_message_dialog "unable to calculate DVD start time from #{command}?" unless outs.length == 2
      outs
    end
    
    def get_start_stop_times_strings
        # only show this message once :)
        @show_block ||= show_blocking_message_dialog(<<-EOL, "Preview")
          Ok, let's preview just a portion of it. 
          Note that you'll want to preview a section that wholly includes an edit section within it.
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
          # this one is raw showMessageDialog...
          JOptionPane.showMessageDialog(nil, " Please choose start and end", "Failed", JOptionPane::ERROR_MESSAGE)
          return
        end
        LocalStorage['start_time'] = start_time
        LocalStorage['end_time'] = end_time
        [start_time, end_time]
    end
    
    def create_brand_new_dvd_edl
	    hashes, title_lengths = get_disk_info # has a prompt
	    volume = hashes['volume_name']
	    default_english_name = volume.split('_').map{|word| word.downcase.capitalize}.join(' ') # turn it into A Court A Jester
      english_name = get_user_input("Enter a human readable DVD descriptive name for #{volume}", default_english_name)

      # EDL versions:
	    # nothing with disk_unique_id: probably dvd_start_offset 29.97
      # nothing without disk_unque_id: probably start_zero 29.97
      # 1.1: has timestamps_relative_to, I guess
	  # 1.2: default to file offsets now...or try to, I guess?
      # 1.3: now has plus and minus? dvd_title_track_start_offset
      input = <<-EOL
# edl_version 1.3, sensible cinema v#{VERSION}
# comments can go be created by placing text after a # on any line, for example this one.
"name" => "#{english_name}",

"mutes" => [
  # an example line, uncomment the leading "#" to make it active
  # "0:00:01.0", "0:00:02.0", "profanity", "da..", 
],

"blank_outs" => [
  # an example line, uncomment the leading "#" to make it active
  # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
],

"source" => "dvd",
"volume_name" => "#{volume}",
"timestamps_relative_to" => ["file", "29.97"],
"disk_unique_id" => "#{hashes['disk_unique_id']}",
"dvd_title_track" => "#{hashes['dvd_title_track']}", # our guess for it
"dvd_title_track_length" => "#{hashes['dvd_title_track_length']}", 
# "not edited out stuff" => "some...",
# "closing thoughts" => "only ...",
# "subtitles_to_display_relative_path" => "some_file.srt" # if you want to display some custom subtitles alongside your movie
"dvd_title_track_start_offset" => "#{hashes['dvd_title_track_start_offset']}",
"dvd_nav_packet_offset" => #{hashes['dvd_nav_packet_offset'].inspect},
        EOL
		# unix2dos so notepad.exe can get them :|
	  input.gsub!("\r\n", "\n")
	  input.gsub!("\n", "\r\n")
		
      filename = EdlParser::EDL_DIR + "/" + english_name.gsub(' ', '_') + '.edl.txt'
      if File.exist?(filename)
	      show_blocking_message_dialog 'don\'t want to overwrite a file in the edit dir that already has same name, opening it instead...'
	    else
	      File.binwrite(filename, input)
      end
      open_file_to_edit_it filename
    end    

    def show_mplayer_instructions
      show_non_blocking_message_dialog <<-EOL
        About to run mplayer.  To control it (or smplayer), you can use these keyboard keys:
        spacebar : pause,
        double clicky/right click/'f' : toggle full screen,
        enter : select DVD menu currently highlighted
        arrow keys (left, right, up down, pg up, pg dn) : seek/scan
        / and *	: inc/dec volume.
        'o' key: turn on on-screen-display timestamps see wiki "understanding timestamps"
        'v' key: toggle display of subtitles.
        '.' key: step forward one frame.
        '#' key: change audio language track
        'j' : change subtitle track/language
   		  [ and ] make playback faster or slower [like 2x]
      EOL
    end
	
    def create_new_for_file_or_netflix
	names = ['movie file', 'netflix instant']
        dialog = DropDownSelector.new(self, names, "Select type")
        type = dialog.go_selected_value
        extra_options = {}
        if type == 'movie file'
          path = SimpleGuiCreator.new_previously_existing_file_selector_and_go "Select file to create EDL for"
          guess_name = File.basename(path).split('.')[0..-2].join('.') # like yo.something.720p.HDTV.X264-DIMENSION.m4v maybe?
          extra_options['filename'] = File.basename path
          require 'lib/movie_hasher'
          extra_options['movie_hash'] = MovieHasher.compute_hash path
        else
          url = get_user_input "Please input the movies url (like http://www.netflix.com/Movie/Curious-George/70042686 )" #?
          if url =~ /netflix/
            guess_name = url.split('/')[-2]
          else
            show_blocking_message_dialog "non hulu/netflix? please report!"
            type = 'unknown'
            guess_name = url.split('/')[-1]
          end
          extra_options['url'] = url
        end
        english_name = get_user_input "Enter descriptive name for movie", guess_name.gsub(/[-._]/, ' ')
        filename = new_nonexisting_filechooser_and_go 'Pick new EDL filename', EdlParser::EDL_DIR + '/..', english_name.gsub(' ', '_') + '.edl.txt'
        display_and_raise "probably needs .txt extension?" unless filename =~ /\.txt$/i
        
        output = <<-EOL
# edl_version 1.2.1, created by sensible cinema v#{VERSION}
# comments can go be created by placing text after a # on any line, for example this one.
"name" => "#{english_name}",

"source" => "#{type}",
#{extra_options.map{|k, v| %!\n"#{k}" => "#{v}",\n!}}
"mutes" => [
  # an example line, uncomment the leading "#" to make it active
  # "0:00:01.0", "0:00:02.0", "profanity", "da..", 
],

"blank_outs" => [
  # an example line, uncomment the leading "#" to make it active
  # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
],

"timestamps_relative_to" => ["#{type}"],
# "not edited out stuff" => "some...",
# "closing thoughts" => "only ...",
# "subtitles_to_display_relative_path" => "some_file.srt" # if you want to display some custom subtitles alongside your movie
        EOL
        File.write filename, output
        open_file_to_edit_it filename

	  end

  end
end
