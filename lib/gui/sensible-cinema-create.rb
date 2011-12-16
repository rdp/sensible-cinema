module SensibleSwing
  
  class MainWindow

    def open_edl_file_when_done thred, filename
      Thread.new {
        thred.join
        open_file_to_edit_it filename
      }
    end

    def setup_advanced_buttons
    
      new_jbutton("Display the standard buttons") do
        window = new_child_window
        window.setup_normal_buttons
      end
      
      add_text_line 'Create: View Options:'
      
      @mplayer_edl = new_jbutton( "Watch DVD edited (realtime) (mplayer) (no subtitles)")
      @mplayer_edl.on_clicked {
        watch_dvd_edited_realtime_mplayer false
      }
      
      @mplayer_edl_with_subs = new_jbutton( "Watch DVD edited (realtime) (mplayer) (yes subtitles)") do
        watch_dvd_edited_realtime_mplayer true
      end
      
      @mplayer_partial = new_jbutton( "Watch DVD edited (realtime) (mplayer) based on timestamp") do
        times = get_start_stop_times_strings
        times.map!{|t| EdlParser.translate_string_to_seconds t}
        start_time = times[0]
        end_time = times[1]
        extra_mplayer_commands = ["-ss #{start_time}", "-endpos #{end_time - start_time}"]
        play_smplayer_edl_non_blocking nil, extra_mplayer_commands, true, false, add_end = 0.0, add_begin = 0.0 # create mode => aggressive
      end
      
      @play_smplayer = new_jbutton( "Watch full DVD unedited (realtime smplayer)")
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

      @play_mplayer_raw = new_jbutton( "Watch full DVD unedited (realtime mplayer)")
      @play_mplayer_raw.tool_tip = <<-EOL
        This is also useful for comparing subtitle files to see if they have accurate timings.
        If you turn on subtitles (use the v button), then compare your srt file at say, the 1 hour mark, or 2 hour mark,
        with the subtitles that mplayer displays, it *should* match exactly with the output in the command line,
        like "V: 3600.0" should match your subtitle line "01:00:00,000 --> ..."
        NB That you can get the mplayer keyboard control instructions with the show instructions button.
      EOL
      @play_mplayer_raw.on_clicked {
        play_dvd_smplayer_unedited true
      }
      
      new_jbutton("Display mplayer keyboard commands/howto") do
        show_mplayer_instructions
      end

      add_text_line 'Create Edit Options:'
      
      @open_current = new_jbutton("Open/Edit EDL for currently inserted DVD") do
        drive, volume_name, dvd_id = choose_dvd_drive_or_file true # require a real DVD disk :)
        edit_list_path = EdlParser.single_edit_list_matches_dvd(dvd_id)
        if edit_list_path
          open_file_to_edit_it edit_list_path
        else
          show_blocking_message_dialog "EDL for this dvd doesn't exist yet, maybe create it first? #{volume_name}"
        end
      end
      
      @create_new_edl_for_current_dvd = new_jbutton("Create new Edit List for currently inserted DVD", 
          "If your DVD doesn't have an EDL created for it, this will be your first step--create an EDL file for it.")
      @create_new_edl_for_current_dvd.on_clicked do
  	    drive, volume_name, dvd_id = choose_dvd_drive_or_file true # require a real DVD disk :)
        edit_list_path = EdlParser.single_edit_list_matches_dvd(dvd_id, true)
        if edit_list_path
		      if show_select_buttons_prompt('It appears that one or more EDL\'s exist for this DVD already--create another?', {}) == :no
		        raise 'aborting'
		      end
		    end	  
        create_brand_new_dvd_edl
      end
      
      new_jbutton("Create new Edit List (for netflix instant or a movie file)") do # TODO VIDEO_TS here too?
        names = ['movie file', 'netflix instant']
        dialog = DropDownSelector.new(self, names, "Select type")
        type = dialog.go_selected_value
        extra_options = {}
        if type == 'movie file'
          path = SwingHelpers.new_previously_existing_file_selector_and_go "Select file to create EDL for"
          guess_name = File.basename(path).split('.')[0..-2].join('.') # Boss.S01E07.720p.HDTV.X264-DIMENSION.m4v
          extra_options['filename'] = File.basename path
          require 'lib/movie_hasher'
          extra_options['movie_hash'] = MovieHasher.compute_hash path
        else
          url = get_user_input "Please input the movies url (like http://www.netflix.com/Movie/Curious-George/70042686 )"
          if url =~ /netflix/
            guess_name = url.split('/')[-2]
          else
            show_blocking_message_dialog "non hulu/netflix? please report!"
            type = 'unknown'
            guess_name = url.split('/')[-1]
          end
          extra_options['url'] = url
        end
        p 'guessed english name:' + guess_name
        english_name = get_user_input "Enter name of movie", guess_name.gsub(/[-._]/, ' ')
        filename = new_nonexisting_filechooser_and_go 'Pick new EDL filename', EdlParser::EDL_DIR + '/..', english_name.gsub(' ', '_') + '.txt'
        display_and_raise "needs .txt extension" unless filename =~ /\.txt$/i
        
        output = <<-EOL
# edl_version_version 1.1, sensible cinema v#{VERSION}
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
# "subtitle_url" => "http://...",
# "not edited out stuff" => "some...",
# "closing thoughts" => "only ...",
# "subtitles_to_display_relative_path" => "file.srt" # if you want to display some custom subtitles alongside your movie
        EOL
        File.write filename, output
        open_file_to_edit_it filename
      end
      
      @open_list = new_jbutton("Open/Edit an arbitrary Edit List file", "If your DVD has a previously existing EDL for it, you can open it to edit it with this button.")
      @open_list.on_clicked {
        filename = new_existing_file_selector_and_select_file("Pick any file to open in editor", 
          LocalStorage['edit_from_here'] || EdlParser::EDL_DIR)
        LocalStorage['edit_from_here'] = File.dirname(filename)
        open_file_to_edit_it filename
      }
      
      @parse_srt = new_jbutton("Scan a subtitle file (.srt) to detect profanity timestamps automatically" )
      @parse_srt.tool_tip = <<-EOL
        You can download a .srt file and use it to programmatically search for the location of various profanities.
        Basically download it from opensubtitles.org (or engsub.net et al),
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
        srt_filename = new_existing_file_selector_and_select_file("Pick srt file to scan for profanities:", File.expand_path('~'))
		    if(srt_filename =~ /utf16/) # from subrip sometimes
		      show_blocking_message_dialog "warning--filename #{srt_filename} may be in utf16, which we don't yet parse"
        end
        # TODO nuke, or do I use them for the 600.0 stuff?
        add_to_beginning = "0.0"#get_user_input("How much time to subtract from the beginning of every subtitle entry (ex: (1:00,1:01) becomes (0:59,1:01))", "0.0")
        add_to_end = "0.0"#get_user_input("How much time to add to the end of every subtitle entry (ex: (1:00,1:04) becomes (1:00,1:05))", "0.0")
        
        open_file_to_edit_it srt_filename
        sleep 0.5 # let it open in TextEdit/Notepad first
    		bring_to_front
 
		    if JOptionPane.show_select_buttons_prompt("Would you like to enter timing adjust information on the .srt file?\n  (on the final pass you should, even if it already matches well, for future use/information' sake)") == :yes
          if JOptionPane.show_select_buttons_prompt("Would you like to start playing it in smplayer, to be able to search for timestamps?\n [use 'v' to turn on subtitles, 'o' to turn on the On screen display timestamps, arrow keys to search, and '.' to pinpoint]?") == :yes
            play_dvd_smplayer_unedited false
          end
          start_text = get_user_input("enter the text from any subtitle entry near beginning [like \"Hello, welcome to our movie.\"]\nctrl-v to paste", "...")
          start_srt = get_user_input("enter beginning timestamp within the .srt file #{File.basename(srt_filename)[0..10]}... for \"#{start_text}\"\nctrl-v to paste", "00:00:00,000")
          start_movie_ts = get_user_input("enter beginning timestamp within the movie itself for said text", "0:00:00")
        
          end_text = get_user_input("enter the text from a subtitle entry far within or near the end of the movie\nctrl-v to paste", "...")
          end_srt = get_user_input("enter the beginning timestamps within the .srt for \"#{end_text}\"\nctrl-v to paste", "02:30:00,000")
          end_movie_ts  = get_user_input("enter beginning timestamps within the movie itself for \"#{end_text}\"", "2:30:00.0 or 9000.0")
        else
		      start_srt = 0
          start_movie_ts =0
          end_srt = 1000
          end_movie_ts = 1000
    		end
        parsed_profanities = SubtitleProfanityFinder.edl_output srt_filename, {}, add_to_beginning.to_f, add_to_end.to_f, start_srt, start_movie_ts, end_srt, end_movie_ts
        filename = EdlTempFile + '.parsed.txt'
        File.write filename, "# add these into your mute section if you deem them mute-worthy\n" + parsed_profanities +
          %!\n\n#Also add these two lines for later coordination:\n"beginning_subtitle" => ["#{start_text}", "#{start_movie_ts}"],! +
           %!\n"ending_subtitle_entry" => ["#{end_text}", "#{end_movie_ts}"]!
        open_file_to_edit_it filename
      end

      @display_dvd_info = new_jbutton( "Display information about current DVD (ID, timing...)" )
      @display_dvd_info.tool_tip = "This is useful to setup a DVD's 'unique ID' within an EDL for it. \nIf your EDL doesn't have a line like disk_unique_id => \"...\" then you will want to run this to be able to add that line in."
      @display_dvd_info.on_clicked {
        out_hashes, title_lengths = get_disk_info
	      out_string = out_hashes.map{|name, value| name.inspect + ' => ' + value.inspect  + ','}.join("\n") + "\n" + title_lengths.join("\n")
        filename = EdlTempFile + '.disk_info.txt'
        File.write filename, out_string
        open_file_to_edit_it filename
        out_string # for unit tests :)
      }
      
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
        thirty_fps = get_user_input("Enter your DVD/hardware/OSD (30 fps) timestamp, I'll convert it to 29.97 (usable in EDL's):", "1:00:00.1")
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
      
      add_text_line 'Create Options with local intermediary file:'
      
      new_jbutton("Show options with local intermediary file") do
        window = new_child_window
        window.add_options_that_use_local_files
      end
      
      if we_are_in_developer_mode?
       @reload = new_jbutton("reload bin/sensible-cinema code") do
         for file in Dir[__DIR__ + '/*.rb']
           p file
           eval(File.read(file), TOPLEVEL_BINDING, file)
         end
       end
      end
      
    end
    
    def display_and_raise error_message
      show_blocking_message_dialog error_message
      raise error_message
    end
    
    def with_autoclose_message(message)
      a = show_non_blocking_message_dialog message
      yield
      a.close
    end
	
    def get_disk_info
	    drive, volume_name, dvd_id = choose_dvd_drive_or_file true # require a real DVD disk :)
      # display it, allow them to copy and paste it out
	    out_hashes = {}
	    out_hashes['disk_unique_id'] = dvd_id
	    out_hashes['volume_name'] = volume_name
      popup = show_non_blocking_message_dialog "calculating DVD title sizes..."
      command = "mplayer -vo direct3d dvdnav:// -nocache -dvd-device #{drive} -identify -frames 0 2>&1"
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
      title_lengths = title_lengths_output.split("\n").select{|line| line =~ /TITLE.*LENGTH/}
      # ID_DVD_TITLE_4_LENGTH=365.000
      titles_with_length = title_lengths.map{|name| name =~ /ID_DVD_TITLE_(\d+)_LENGTH=([\d\.]+)/; [$1, $2.to_f]}
      largest_title = titles_with_length.max_by{|title, length| length}
  	  if !largest_title
  	    show_blocking_message_dialog "unable to parse title lengths? maybe need to clean disk? #{title_lengths_output}"
        raise
	    end
	    largest_title = largest_title[0]
      title_to_get_offset_of ||= largest_title
 	    out_hashes['dvd_title_track'] = title_to_get_offset_of
	    out_hashes['dvd_title_track_length'] = titles_with_length.detect{|title, length| title == title_to_get_offset_of}[1]
      offsets = calculate_dvd_start_offset(title_to_get_offset_of, drive)
    	start_offset = offsets[:mpeg_start_offset]
	    out_hashes['dvd_start_offset'] = start_offset
      out_hashes['dvd_nav_packet_offset'] = offsets[:dvd_nav_packet_offset]
	    [out_hashes, title_lengths]
    end
	
    def watch_dvd_edited_realtime_mplayer show_subs
        edl_out_command = ""
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
          
        end
        thred = play_smplayer_edl_non_blocking nil, [edl_out_command], true, false, add_end = 0.0, add_begin = 0.0, show_subs # more aggressive :)
        if(edl_out_command.present?)
          open_edl_file_when_done thred, edlout_filename
        end
    end
    
    def calculate_dvd_start_offset title, drive # TODO use *their* main title if has one...
      popup = show_non_blocking_message_dialog "calculating start info for title #{title}..." # must be non blocking so the command can run :P
      command = "mplayer -benchmark -frames 35  -osd-verbose -osdlevel 2 -vo null -nosound dvdnav://#{title} -nocache -dvd-device #{drive}  2>&1"
      puts command
      out = `#{command}`
      #search for V:  0.37
      popup.close
      outs = {}
      out.each_line{|l|
        if l =~  /V:\s+([\d\.]+)/
          outs[:mpeg_start_offset] ||= $1.to_f
        end
	      float = /\d+\.\d+/
	      if l =~ /last NAV packet was (#{float}), mpeg at (#{float})/
          nav = $1.to_f
          mpeg = $2.to_f
          if nav > 0.0
	          outs[:dvd_nav_packet_offset] ||= [nav, mpeg]
          end
      	end
      }
      show_blocking_message_dialog "unable to calculate time?" unless outs.length == 2
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
	    default_english_name = volume.split('_').map{|word| word.downcase.capitalize}.join(' ') # A Court A Jester
      english_name = get_user_input("Enter a human readable DVD description for #{volume}", default_english_name)

      # EDL versions:
	    # nothing with disk_unique_id: probably dvd_start_offset 29.97
      # nothing without disk_unque_id: probably start_zero 29.97
      # 1.1: has timestamps_relative_to, I guess
    
      input = <<-EOL
# edl_version_version 1.1, sensible cinema v#{VERSION}
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
"timestamps_relative_to" => ["dvd_start_offset","29.97"],
"disk_unique_id" => "#{hashes['disk_unique_id']}",
"dvd_title_track" => "#{hashes['dvd_title_track']}", # the longest title is usually the main
"dvd_title_track_length" => "#{hashes['dvd_title_track_length']}", 
# "subtitle_url" => "http://...",
# "not edited out stuff" => "some...",
# "closing thoughts" => "only ...",
# "subtitles_to_display_relative_path" => "file.srt" # if you want to display some custom subtitles alongside your movie
"dvd_title_track_start_offset" => "#{hashes['dvd_start_offset']}",
"dvd_nav_packet_offset" => #{hashes['dvd_nav_packet_offset'].inspect},
        EOL
      filename = EdlParser::EDL_DIR + "/edls_being_edited/" + english_name.gsub(' ', '_') + '.txt'
      filename.downcase!
      if File.exist?(filename)
	    show_blocking_message_dialog 'cannot overwrite file in the edit dir'
	  else
	    File.write(filename, input)
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
   		  [ and ] make playback faster
      EOL
    end

  end
end
