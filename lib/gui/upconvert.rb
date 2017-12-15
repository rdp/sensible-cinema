
module SensibleSwing
  
  class MainWindow
   
    def add_play_upconvert_buttons
    
      @watch_file_upconvert = new_jbutton( "Watch a movie file upconverted (unedited)") do
        popup = warn_if_no_upconvert_options_currently_selected
        filename_mpg = new_existing_file_selector_and_select_file( "pick movie file (like moviename.mpg)")
        thread = play_smplayer_edl_non_blocking [filename_mpg, nil]
        when_thread_done(thread) { popup.dispose }
      end
      @watch_file_upconvert.tool_tip= "This plays back a movie file, like moviefile.mpg, or moviename.vob using your current upconverter settings.\nTo playback a file edited upconverted, set upconvert options here first, then run them using sensible cinema main--it will automatically use your new upconverting options.\n" # LODO
      
      @watch_dvd_upconvert = new_jbutton( "Watch a DVD upconverted (unedited)") do
        popup = warn_if_no_upconvert_options_currently_selected
        thread = play_dvd_smplayer_unedited false
        when_thread_done(thread) { popup.dispose }
      end
      @watch_dvd_upconvert.tool_tip = "Plays back the currently inserted DVD, using your current upconverter settings.\nIf it fails (dies immediately, blank screen, etc.), try setting upconvert options to a smaller screen resolution multiple.\nOr try playing the DVD with VLC first, then it might work.\nTo playback a DVD edited upconverted, set upconvert options here first, then run them using sensible cinema main--it will automatically use your new upconverting options."
      
      @watch_online = new_jbutton( "Watch upconverted online player, like netflix instant") do
	    show_blocking_message_dialog("sorry not mac compat. yet") and raise unless OS.doze?
		warn_if_no_upconvert_options_currently_selected
        for type, url in {'screen capture grabber device' => "https://github.com/rdp/screen-capture-recorder-to-video-windows-free", 'avisynth 32-bit' => "http://avisynth.org/mediawiki/Main_Page"}
          answer = JOptionPane.show_select_buttons_prompt("Warning: you must have the #{type} previously installed.", :yes => 'take me to its website', :no => 'I already and installed it!') # guess we could auto-detect...
          if answer == :yes
             SimpleGuiCreator.open_url_to_view_it_non_blocking url
             raise 'install them then click this button again'
          end
		end
		SimpleGuiCreator.show_text "you will want to first configure the capture device by 
		starting the video playing, 
		then run programs -> screen capture recorder -> configure -> by resizing a transparent window
		position it exactly over the video, then click ok.  Click ok here when that has been done."
        run_smplayer_non_blocking "upconvert_from_screen/upconvert_from_screen_me2.avs", nil, '', force_mplayer = true, true, false, nil
      end
      
      add_text_line ''
      @upconv_line = add_text_line ''
      change_upconvert_line_to_current
      
      add_change_upconvert_options_button
      if !upconvert_set_to_anything?
        show_blocking_message_dialog 'please configure your upconvert settings first'
        @show_upconvert_options.simulate_click # make them choose one
      end
      add_text_line ''
      
    end
    
    def upconvert_set_to_anything?
      LocalStorage[UpConvertEnglish].present?
    end
    
    LocalStorage.set_default('screen_multiples', 1.0)

    def add_change_upconvert_options_button
      @show_upconvert_options = new_jbutton("Tweak Playback Upconversion Quality Settings") do
        upconvert_window = new_child_window
        upconvert_window.add_change_upconvert_buttons
      end
      @show_upconvert_options.tool_tip= "Allows you to set your upconvert options.\nUpconverting attempts to playback your movie with higher quality on high resolution monitors."
    end
    
    
    def warn_if_no_upconvert_options_currently_selected
      if !upconvert_set_to_anything?
        show_non_blocking_message_dialog "Warning: upconvert options have not been set yet--set upconvert options first, if desired."
      else
        JFrame.new # something it can call dispose on :P
      end
    end
    
    def change_upconvert_line_to_current
      current = get_current_upconvert_as_phrase
      if @upconv_line
        @upconv_line.set_text current
      end
      if @parent && @parent.upconv_line
        @parent.upconv_line.set_text current
      end # LODO I think the child also wants a status line..
    end
    
    UpConvertKey = 'upconvert_setting'
    UpConvertKeyExtra = 'upconvert_setting_extra'
    UpConvertEnglish = 'upconvert_english_name'
    ScreenMultipleFactor = 'screen_multiples'

	def setup_dvd_upconvert_options
	    luma_spatial = 0
        chroma_spatial = 1
        luma_tmp = 4
        chroma_tmp = 4
		# SCREEN_X is replaced later.
        LocalStorage[UpConvertKey] = "hqdn3d=%s:%s:%s:%s,scale=SCREEN_X:-10:0:0:2" % [luma_spatial, chroma_spatial, luma_tmp, chroma_tmp]
        # hqdn3d[=luma_spatial:chroma_spatial:luma_tmp:chroma_tmp]
        LocalStorage[UpConvertKeyExtra] = "-sws 9 -ssf ls=75.0 -ssf cs=7.0" # 9 is lanczos
        LocalStorage[UpConvertEnglish] = "DVD"
    end
	
	def reset_upconversion_options
	    LocalStorage[UpConvertKey] = nil
        LocalStorage[UpConvertKeyExtra] = nil
        LocalStorage[UpConvertEnglish] = nil
    end
	
    def add_change_upconvert_buttons
      raise 'should have already been set for us' unless LocalStorage[ScreenMultipleFactor]
      @medium_dvd = new_jbutton("Set upconvert options to DVD-style video") {
	    setup_dvd_upconvert_options
        display_current_upconvert_setting_and_close_window
      }
      high_compression = new_jbutton("Set upconvert options to high compressed video file playback") {
        # -autoq 6 -vf pp [?]
        LocalStorage[UpConvertEnglish] = "high compressed"
        LocalStorage[UpConvertKey] = "hqdn3d=0:1:4:4,pp=hb:y/vb:y,scale=SCREEN_X:-10:0:0:3" # pp should be after hqdn3d I think... and hqdn3d should be before scale...
        LocalStorage[UpConvertKeyExtra] = "-sws 9 -ssf ls=75.0 -ssf cs=25.0"
        display_current_upconvert_setting_and_close_window
        # -Processing method: mplayer with accurate deblocking ???
      }
      new_jbutton("Set upconvert options to experimental screen-upconverting playback") {
        LocalStorage[UpConvertKey] = "scale=SCREEN_X:-10:0:0:3" # no hqdn3d
        LocalStorage[UpConvertKeyExtra] = "-sws 9 -ssf ls=75.0 -ssf cs=25.0"
        LocalStorage[UpConvertEnglish] = "experimental screenupconversion"
        display_current_upconvert_setting_and_close_window
      }
      
      new_jbutton("Set upconvert options to whatever you want [like -sws 9 -ssf ls=100.0 -- for advanced users]") {
        new_settings = get_user_input("you can set -vf settings, and then other settings. What would you like your -vf settings to be?")
        LocalStorage[UpConvertKey] = new_settings
        other_settings = get_user_input("other settings you'd like to also have add:")
        LocalStorage[UpConvertKeyExtra] = other_settings
        LocalStorage[UpConvertEnglish] = "personalized: -vf #{new_settings}, #{other_settings}"      
      }
      
      # TODO tooltip from docu here +- this into tooltip
      # TODO "click here" link for more docu [?]
      add_text_line "Multiple factor screen widths"
      add_text_line "   (higher might be better, uses more cpu)." 
      add_text_line "   If mplayer just dies or displays only a black or white screen then lower this setting, it is too high."
      slider = JSlider.new
      slider.setBorder(javax.swing.BorderFactory.createTitledBorder("Screen resolution multiple"));
  
      # I want tick for 1x, 1.5x, 2x, 2.5x, 3x
      # so let's do marker values of 10 -> 30, since it requires integers...
      
      labelTable = java.util.Hashtable.new
      i = java.lang.Integer
      l = JLabel
      
      # allow for 0.75 too, if you have a large monitor, slower cpu...
      local_minimum = (720.0/get_current_max_width_resolution)*100 # allows 1024 to use upscaling to 860, but we warn when they do this
      label_minimum = nil
      (0..300).step(25) do |n|
        if n > local_minimum
          label_minimum ||= n
          if (n % 100 == 0)
            labelTable.put(i.new(n), l.new("#{n/100}x")) # 1x
          elsif n == label_minimum # just for the bottom label, rest too chatty
            labelTable.put(i.new(n), l.new("#{n/100.0}x")) # 1.5x
          end
        end
      end
      slider.setLabelTable( labelTable )
  
      slider.maximum=300
      slider.minimum=label_minimum
      slider.setMajorTickSpacing(100) 
      slider.setMinorTickSpacing(25) 
      slider.setPaintTicks(true)
      slider.setPaintLabels(true)    
      slider.snap_to_ticks=true
      
      slider.set_value LocalStorage[ScreenMultipleFactor] * 100
      
      slider.add_change_listener { |event|
        if !slider.value_is_adjusting
          # they released their hold on it...
          old_value = LocalStorage[ScreenMultipleFactor]
          new_value = slider.value/100.0
          LocalStorage[ScreenMultipleFactor] = new_value
          if new_value != old_value
            if slider.value == label_minimum
              show_blocking_message_dialog "Setting it too low like that might make it not do much upconverting (DVD's, are 720px, you're setting it to upconvert to #{new_value * get_current_max_width_resolution})"
            end
            display_current_upconvert_setting_and_close_window
          end
        end
      }
      slider.set_bounds(44, @starting_button_y, @button_width, 66)
      2.times {increment_button_location}
      @panel.add(slider)
      
      increment_button_location
      
      @none = new_jbutton("Reset upconvert options to none (no upconversion)")
      @none.tool_tip = "Having no upconvert options is reasonably good, might use directx for scaling, nice for slow cpu's"
      @none.on_clicked {
        reset_upconversion_options
        display_current_upconvert_setting_and_close_window
      }
      
      @generate_images = new_jbutton("Test current configuration by writing some images from playing a video file") do
        popup = warn_if_no_upconvert_options_currently_selected
        filename_mpg = new_existing_file_selector_and_select_file( "pick movie file (like moviename.mpg)")
        
        output_dir = get_same_drive_friendly_clean_temp_dir 'temp_upscaled_video_out'
        output_command = '-ss 2:44 -frames 300 -vo png:outdir="' + File.strip_drive_windows(output_dir) + '"'
        output_command += " -noframedrop" # don't want them to skip frames on cpu's without enough power to keep up
        thread = play_smplayer_edl_non_blocking [filename_mpg, nil], [output_command], true
        when_thread_done(thread) { popup.dispose; show_in_explorer(output_dir) }
      end
      @generate_images.tool_tip = "This creates a folder with images upconverted from some DVD or file, so you can tweak settings and compare." # TODO more tooltips

      @generate_screen_cast = new_jbutton("Test current configuration by watching video file and recording screen") do
        check_for_ffmpeg_installed
		popup = warn_if_no_upconvert_options_currently_selected
        filename_mpg = new_existing_file_selector_and_select_file( "pick movie file (like moviename.mpg)")
        output_dir = get_same_drive_friendly_clean_temp_dir 'temp_screencast_dir'
        thread1 = play_smplayer_edl_non_blocking [filename_mpg, nil], [" -ss 2:44 -endpos 11"]
        # screen capture for 10s
        fps_to_grab = 5
		
        thread2 = Thread.new {  c = %!ffmpeg -f dshow -i video="screen-capture-recorder" -r #{fps_to_grab} -vframes #{fps_to_grab*10} -y #{File.strip_drive_windows(output_dir)}/%d.png!; system_blocking c }
        thread2.join
        show_blocking_message_dialog "ffmpeg done, close mplayer now!"
        thread1.join
        popup.dispose # just in case :P
        show_in_explorer(output_dir)
      end


    end
    
    def get_same_drive_friendly_clean_temp_dir suffix
        output_dir = Dir.tmpdir
        if File.get_root_dir(output_dir) != File.get_root_dir(Dir.pwd) # you are hosed!
          output_dir = File.get_root_dir(Dir.pwd) # we'll raise if it's not writable...
        end
        output_dir = output_dir + '/' + suffix
        FileUtils.rm_rf output_dir
        Dir.mkdir output_dir
        output_dir
    end
    
    def display_current_upconvert_setting_and_close_window
      change_upconvert_line_to_current
      show_blocking_message_dialog get_current_upconvert_as_phrase
      self.dispose
    end
    
    def get_current_upconvert_as_phrase
      settings = LocalStorage[UpConvertEnglish]
      out = "Upconvert options are now #{  settings ? "set to #{settings} style" : "NOT SET"}"
      if settings
        multiple = LocalStorage[ScreenMultipleFactor]
        out += " (screen multiplier #{multiple}*#{get_current_max_width_resolution} = #{(multiple * get_current_max_width_resolution).to_i}px)."
      end
      out
    end
    
    def get_current_max_width_resolution
      # choose width of widest monitor (why would they display it on the other, right?)
      java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment.getScreenDevices.map{|gd| gd.display_mode.width}.max.to_i
    end
    
    def get_upconvert_vf_settings
      template = LocalStorage[UpConvertKey]
      if template
        screen_multiple = LocalStorage[ScreenMultipleFactor]
        upc = template.gsub('SCREEN_X', (get_current_max_width_resolution*screen_multiple).to_i.to_s) # has to be an integer...
        upc = 'pullup,softskip,' + upc
		show_non_blocking_message_dialog 'using upconversion settings ' + upc
        p 'using upconvert settings: ' + upc
        raise 'unexpected' if upc =~ /"/ # keep things smplayer sane
		upc
      else
        p 'not using any specific upconversion-ing'
        # pullup, softskip -- might slow things down too much for slow cpus [?]
		''
      end
    end

    def get_upconvert_secondary_settings
      LocalStorage[UpConvertKeyExtra]
    end

 
  end
end
    
