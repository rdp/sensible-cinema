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

alias system_original system
require 'fileutils'

class String
  def snake_case
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
  def quotify
    '"' + self + '"'
  end
end

# a few I'll always need no matter what...
require_relative '../jruby-swing-helpers/lib/simple_gui_creator'
require_relative '../jruby-swing-helpers/lib/simple_gui_creator/storage'
require_relative '../jruby-swing-helpers/lib/simple_gui_creator/drive_info'
require_relative '../edl_parser'
require 'tmpdir'
require 'whichr'
require 'os'

if OS.doze?
  autoload :EightThree, './lib/eight_three'
end

# attempt to load on demand...i.e. faster...gah
for kls in [:MplayerEdl, :SubtitleProfanityFinder, :ConvertThirtyFps]
  autoload kls, "./lib/#{kls.to_s.snake_case}"
end

class String
  def to_filename
    SimpleGuiCreator.to_filename(self)
  end
end

if OS.windows?
  vendor_cache = File.expand_path(File.dirname(__FILE__)) + '/../../vendor/cache'
  for name in ['.', 'ffmpeg', 'mplayer_edl']
    # put them all at the beginning of the PATH
    ENV['PATH'] = (vendor_cache + '/' + name).to_filename + ';' + ENV['PATH']
  end
  
  def add_smplayer_paths
    discovered_smplayer_folders = Dir['{c,d,e,f,g}:/program files*/smplayer']

    for folder in discovered_smplayer_folders
      ENV['PATH'] = ENV['PATH'] + ";#{folder.gsub('/', "\\")}"
    end
  end
  
  add_smplayer_paths

else
  # handled in check_mac_installed.rb file
end

# not sure where to put this method...
    def mplayer_local add_quotes = true
      if OS.doze?
        loc = File.expand_path("vendor/cache/mplayer_edl/mplayer.060.exe") # also edit mplayer_up_to_date method if you change this...maybe?
		if add_quotes
		  loc = '"' + loc + '"'
		end
		loc
      else
        '/opt/rdp_project_local/bin/mplayer'
      end
    end
import 'javax.swing.ImageIcon'

module SensibleSwing # LODO rename :)
  include SimpleGuiCreator # have access to various swing classes
  VERSION = File.read(File.dirname(__FILE__) + "/../../VERSION").strip
  puts "v. " + VERSION + " " + RUBY_DESCRIPTION # for the console output
  
  UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()) # <sigh>
  
  class MainWindow < JFrame
    include SimpleGuiCreator # various swing classes
    
    def initialize start_visible = true, args = ARGV # lodo not optionals
      super "Clean Editing Movie Player #{VERSION} (GPL)"
      @args = args # save them away so sub windows can "not have to use" ARGV
      force_accept_license_first # in other file :P
      @panel = JPanel.new
      @buttons = []
      @panel.set_layout nil
      add @panel # why can't I just slap these down? panel? huh?
      @starting_button_y = 40
      @button_width = 400      
      
      add_text_line "Welcome to the Clean Editing Movie Player!"
      #@starting_button_y += 10 # kinder ugly...
      #add_text_line "      Rest mouse over buttons for \"help\" type descriptions (tooltips)."
      icon_filename = __DIR__ + "/../../vendor/profs.png"
      raise unless File.exist? icon_filename # it doesn't check this for us?
      setIconImage(ImageIcon.new(icon_filename).getImage())
      if !in_online_player_startup_mode # the other guys need tons of local help...this one is all web
        @current_dvds_line1 = add_text_line "Checking present DVD's..."
        @current_dvds_line2 = add_text_line ""
        @callbacks_for_dvd_edl_present = []
        DriveInfo.create_looping_drive_cacher
        DriveInfo.add_notify_on_changed_disks { update_currently_inserted_dvd_list }      
        check_for_various_dependencies
      end
      LocalStorage.set_once('init_preferences_once') {
	    show_blocking_message_dialog "let's setup user preferences once..."
	    set_individual_preferences
      }
      set_visible start_visible
    end
    
    def add_callback_for_dvd_edl_present &block
      raise unless block
      @callbacks_for_dvd_edl_present << block
      update_currently_inserted_dvd_list # updates them :P
    end
    
    def update_currently_inserted_dvd_list
	    present_discs = []
      DriveInfo.get_dvd_drives_as_openstruct.each{|disk|
        if disk.VolumeName
           dvd_id = DriveInfo.md5sum_disk(disk.MountPoint)			     
           edit_list_path_if_present = EdlParser.single_edit_list_matches_dvd(dvd_id, true)
			     if edit_list_path_if_present
             human_name = parse_edl(edit_list_path_if_present)['name']
			       human_name ||= ''
           end
           present_discs << [human_name, disk.VolumeName, edit_list_path_if_present]
        end
      }
      found_one = false
      present_discs.map!{|human_name, volume_name, has_edl| 
        if human_name
          found_one = true
          "DVD: #{human_name} has an Edit List available! (#{volume_name})"
        else
          "DVD: (#{volume_name}) has NO Edit List available!"
        end
      }
      if present_discs.length > 0
        @current_dvds_line1.text= '      ' + present_discs[0]
        @current_dvds_line2.text= '      ' + present_discs[1..2].join(" ")
      else
        @current_dvds_line1.text= '      No DVD discs currently inserted.'
        @current_dvds_line2.text = ''
      end
      @callbacks_for_dvd_edl_present.each{|c| c.call(present_discs.length > 0, found_one)}
    end
	
    def get_title_track_string descriptors, use_default_of_one = true
      given = descriptors["dvd_title_track"] 
      given ||= "1" if use_default_of_one
      given
    end
	
	def get_srt_filename descriptors, edl_filename
	  path = descriptors['subtitles_to_display_relative_path'] if descriptors
	  if path
	    path = File.expand_path(File.dirname(edl_filename) + '/' + path)
	    raise 'nonexisting srt file must be relative to the edl file...' + path unless File.exist? path
	  end
	  path
	end

    def we_are_in_create_mode
     @args.index("--create-mode")
    end

    def in_online_player_startup_mode
     @args.index("--online-player-mode")
    end
    
    def we_are_in_developer_mode?
      @args.detect{|a| a == '--developer-mode'}
    end
    
    def new_jbutton title, tooltip = nil
      button = JButton.new title
      button.tool_tip = tooltip
      button.set_bounds(44, @starting_button_y, @button_width, 23)
      @panel.add button
      @buttons << button
      if block_given? # allow for new_jbutton("xx") do ... end [this is possible through some miraculous means LOL]
        button.on_clicked { yield }
      end
      increment_button_location
      button
    end
    
    def add_text_line line
      jlabel = JLabel.new line
      happy = Font.new("Tahoma", Font::PLAIN, 11)
      jlabel.setFont(happy)
      jlabel.set_bounds(44,@starting_button_y ,460,14)
      @panel.add jlabel
      increment_button_location 18
      jlabel
    end
    
    def increment_button_location how_much = 30
      @starting_button_y += how_much
      setSize @button_width+80, @starting_button_y + 50
    end
    
    def add_open_documentation_button
      @open_help_file = new_jbutton("View Sensible Cinema Documentation") do
        show_blocking_message_dialog "Documentation has moved to online, ask on the mailing list if there are questions"
        SimpleGuiCreator.open_url_to_view_it_non_blocking "https://github.com/rdp/sensible-cinema/wiki/_pages"
      end
    end
	
    LocalStorage = Storage.new("sensible_cinema_storage_#{VERSION}")
    
    def when_thread_done(thread)
      Thread.new {thread.join; yield }
    end    

    # a window that when closed doesn't bring the whole app down
    def new_child_window
      child = MainWindow.new true, []
      child.parent=self # this should have failed in the PPL
      # make both windows visible by moving the child down and to the right of its parent
      x, y = self.get_location.x, self.get_location.y
      child.set_location(x + 100, y + 100)
      child
    end
    
    def run_smplayer_non_blocking(*args)
      @background_thread = Thread.new {
        run_smplayer_blocking(*args)
      }
    end

    # basically run mplayer/smplayer on a file or DVD
    def run_smplayer_blocking play_this, title_track_maybe_nil, passed_in_extra_options, force_use_mplayer, show_subs, start_full_screen, srt_filename
      puts "starting mplayer..."
	  raise unless passed_in_extra_options # cannot be nil
      extra_options = []
      # -framedrop is for slow CPU's
      # same with -autosync to try and help it stay in sync... -mc 0.03 is to A/V correct 1s audio per 2s video
      # -hardframedrop might help but hurts the eyes just too much
      extra_options << "-framedrop" # even in create mode, if the audio ever gets off, we're hosed with making accurate timestamps...so drop, until I hear otherwise...
      extra_options << "-mc 2"
      extra_options << "-autosync 30" 

	  # allow a larger max volume
	  extra_options << "-nosoftvol -af volume=20.0:0" # amplify without using buggy software mixer softvol--0 is soft clipping off, whatever that means
	  
      extra_options << "-osdlevel 2" # who doesn't want to see those fraction decimal points :)
      if we_are_in_create_mode
        extra_options << "-osd-verbose" if we_are_in_developer_mode?		 # console output
      end
      extra_options << "-osd-fractions 1"
      
      if !show_subs && !srt_filename
        # disable all subtitles :P
        extra_options << "-nosub -noautosub -forcedsubsonly -sid 1000"
      end
	    if srt_filename
	      extra_options << "-sub #{srt_filename}"
  	  else
        extra_options << "-alang en"
        extra_options << "-slang en"
	    end

      force_use_mplayer ||= OS.mac?
      parent_parent = File.basename(File.dirname(play_this))
      if parent_parent == 'VIDEO_TS'
        # case d:\yo\VIDEO_TS\title0.vob
        dvd_device_dir = normalize_path(File.dirname(play_this))
        play_this = "\"dvdnav://#{title_track_maybe_nil}/#{dvd_device_dir}/..\""
      elsif File.exist?(play_this + '/VIDEO_TS') || (play_this =~ /\/dev\/rdisk\d/)
        # case d:\ where d:\VIDEO_TS exists [DVD mounted in drive, or DVD dir] or mac's /dev/rdisk1
        play_this = "\"dvdnav://#{title_track_maybe_nil}/#{play_this}\""
      else
        # case g:\video\filename.mpg
        # leave it the same...
      end
      if play_this =~ /dvdnav/ && title_track_maybe_nil
        extra_options << "-msglevel identify=4" # prevent smplayer from using *forever* to look up info on DVD's with -identify ...
      end
      
      extra_options << "-mouse-movements" # just in case smplayer also needs -mouse-movements... :) LODO it prolly doesn't
	  if get_upconvert_secondary_settings.present?
	    extra_options << get_upconvert_secondary_settings
      end
      extra_options << "-lavdopts threads=#{OS.cpu_count}" # just in case this helps [supposed to with h.264] # NB fast *crashes* doze...
      if force_use_mplayer
        extra_options << "-font #{File.expand_path('vendor/subfont.ttf')}"
	    key_strokes = <<-EOL
RIGHT seek +10
LEFT seek -10
DOWN seek -60
UP seek +60
ENTER {dvdnav} dvdnav select	  
MOUSE_BTN0 {dvdnav} dvdnav select
MOUSE_BTN0_DBL vo_fullscreen
MOUSE_BTN2 vo_fullscreen
KP_ENTER dvdnav select
# some for os x, some for doze. huh?
       EOL
       conf_file = File.expand_path './mplayer_input_conf'
       File.write conf_file, key_strokes
       extra_options << "-volume 100" # why start low? mplayer why oh why LODO tell them not to, also tell them the default should be dvdnavigable, really...yes?
       if OS.windows?
        # direct3d for windows 7 old nvidia cards' sake [yipes] and also dvdnav sake
        extra_options << "-vo direct3d"
        conf_file = conf_file[2..-1] # strip off drive letter, which it doesn't seem to like no sir
       end
       if start_full_screen
         extra_options << "-fs"
         upconv = get_upconvert_vf_settings
         upconv = "-vf #{upconv}" if upconv.present?
       else
        upconv = ""
       end
       mplayer_loc = mplayer_local false
       assert File.exist?(mplayer_loc)
       c = "#{mplayer_loc} #{extra_options.join(' ')} #{upconv} -input conf=\"#{conf_file}\" #{passed_in_extra_options} \"#{play_this}\" "
      else
        if OS.windows?
          extra_options << "-vo direct3d" # more light nvidia...should be ok...this wastes cpu...but we have to have it I guess...
        end
        set_smplayer_opts extra_options.join(' ') + " " + passed_in_extra_options, get_upconvert_vf_settings, show_subs
        c = "smplayer \"#{play_this}\" -config-path \"#{File.dirname  EightThree.convert_path_to_8_3(SMPlayerIniFile)}\" " 
        c += " -fullscreen " if start_full_screen
        if !we_are_in_create_mode
          #c += " -close-at-end " # smplayer close after...still a bit too unstable though...
        end
      end
      puts c
      system_blocking c
    end
    
    SMPlayerIniFile = File.expand_path("~/.smplayer_sensible_cinema/smplayer.ini")
    
    def set_smplayer_opts to_this, video_settings, show_subs = false
      p 'setting smplayer extra opts to this:' + to_this
      old_prefs = File.read(SMPlayerIniFile) rescue ''
      unless old_prefs.length > 0
        # LODO double check the rest here...
        old_prefs = "[%General]\nmplayer_bin=\n[advanced]\nmplayer_additional_options=\nmplayer_additional_video_filters=\n[subtitles]\nautoload_sub=false\n[performance]\npriority=3" 
      end
      raise to_this if to_this =~ /"/ # unexpected, unfortunately... <smplayer bug>
      assert new_prefs = old_prefs.gsub(/mplayer_additional_options=.*/, "mplayer_additional_options=#{to_this}")
      assert new_prefs.gsub!(/autoload_sub=.*$/, "autoload_sub=#{show_subs.to_s}")
      assert new_prefs.gsub!(/mplayer_additional_video_filters=.*$/, "mplayer_additional_video_filters=\"#{video_settings}\"")
      raise 'smplayer on non doze not expected...' unless OS.doze?
      mplayer_to_use = mplayer_local false 
      assert File.exist?(mplayer_to_use)
      new_value = "\"" + mplayer_to_use.to_filename.gsub("\\", '/') + '"' # forward slashes. Weird.
      assert new_prefs.gsub!(/mplayer_bin=.*$/, "mplayer_bin=" + new_value)
      # now some less important ones...
      new_prefs.gsub!(/priority=.*$/, "priority=3") # normal priority...scary otherwise! lodo tell smplayer...
      # enable dvdnav navigation, just for kicks I guess.
      new_prefs.gsub!(/use_dvdnav=.*$/, "use_dvdnav=true")
      
      FileUtils.mkdir_p File.dirname(SMPlayerIniFile)
      File.write(SMPlayerIniFile, new_prefs)
      new_prefs.each_line{|l| print l if l =~ /additional_video/} # debug
    end
    
    def system_blocking command
      return true if command =~ /^@rem/ # JRUBY-5890 bug
      raise command + " failed env #{ENV['PATH']}" unless system_original command
    end
    
    def system_non_blocking command
      @background_thread = Thread.new { system_original command }
    end
    
    # force them choose which system call to use explicitly
    if respond_to? :system
      undef system
    else # it's a reload
    end
   
    # LODO remove now unused parameter...
    def play_dvd_smplayer_unedited use_mplayer_instead
      drive_or_file, dvd_volume_name, dvd_id, edl_path_maybe_nil, descriptors = choose_dvd_or_file_and_edl_for_it(force_choose_edl_file_if_no_easy_match = true)
      title_track_maybe_nil = get_title_track_string(descriptors, false)
      if is_dvd?(drive_or_file)
        dvd_options = get_dvd_playback_options(descriptors)
      else
        dvd_options = ''
      end
      run_smplayer_non_blocking drive_or_file, title_track_maybe_nil, dvd_options, use_mplayer_instead, true, false, get_srt_filename(descriptors, edl_path_maybe_nil)
    end
    
    def get_dvd_playback_options descriptors
      out = []
      
      nav, mpeg_time = descriptors['dvd_nav_packet_offset'] # like [0.5, 0.734067]
	  
      if nav
	    mpeg_time *= 1/1.001 # -> 29.97 fps
        offset_time = mpeg_time - nav
      else
  		  # readings: 0.213  0.173 0.233 0.21 0.18 0.197 they're almost all right around 0.20...
        show_blocking_message_dialog "error--your DVD EDL doesn\'t list a start offset time [dvd_nav_packet_offset] which is needed for precise accurate timing. Please run\nadvanced mode -> Display information about current DVD\nand add it to the EDL. Using a default for now...if you tweak any timing info you may want to set this more accurately first!"
        offset_time = 0.20
      end
	  raise if offset_time < -0.5 # unexpected...except karate kid which actually has a negative...
	  # -osd-add is because the initial NAV packet is "x" seconds off from the mpeg, and since 
	  # we have it set within mplayer to "prefer to just give you the MPEG time when you haven't passed a DVD block"
	  # we wanted to match that more precisely once we did get past it.
	  # so basically today we are trying to "match" the underlying MPEG time well. Which is wrong, of course.
	  # either match the file or match the DVD, punk!
	  
	  mpeg_start = descriptors['dvd_title_track_start_offset']
	  if mpeg_start
	    # TODO rdp mark all current ones [most of them anyway] as file, then this will be appropriate...
	    #unless descriptors["timestamps_relative_to"][0] == ["dvd_start_offset"] # like  ["dvd_start_offset", "29.97"]
          out << "-osd-subtract #{ "%0.3f" % mpeg_start}" # bring it into line with what the "file time" would be, since it skips the initial 0.28s ...
		#else
		#  puts "update me!"
		#end
	  else
	    show_blocking_message_dialog "DVD lacks dvd_title_track_start_offset -- please add it"
	  end
	  
	  out << "-osd-add #{ "%0.3f" % offset_time}"
      out.join(' ')
    end

    if OS.doze? # avoids spaces in filenames :)
      EdlTempFile = EightThree.convert_path_to_8_3(Dir.tmpdir) + '/mplayer.edl' # stay 8.3 friendly, guess we want forward slashes
    else
      raise if Dir.tmpdir =~ / / # that would be unexpected, and possibly cause problems...
      EdlTempFile = Dir.tmpdir + '/mplayer.temp.edl'
    end
    
  	EdlFilesChosen = {} # allow for switching tapes but still cache EDL loc. :P
	
    def choose_dvd_or_file_and_edl_for_it force_choose_edl_file_if_no_easy_match = true
      drive_or_file, dvd_volume_name, dvd_id = choose_dvd_drive_or_file false
      edl_path = EdlFilesChosen[dvd_id]
      if !edl_path
        edl_path = EdlParser.single_edit_list_matches_dvd(dvd_id)
        if !edl_path && force_choose_edl_file_if_no_easy_match
  		    message = "Please pick a DVD Edit List File (none or more than one were found that seem to match #{dvd_volume_name})--may need to create one, if one doesn't exist yet"
		      show_blocking_message_dialog message
          edl_path = new_existing_file_selector_and_select_file(message, EdlParser::EDL_DIR)
        end
      end
      p 're/loading ' + edl_path # in case it has changed on disk
      if edl_path # sometimes they don't have to choose one [?]
        descriptors = nil
        begin
          descriptors = parse_edl edl_path
        rescue SyntaxError => e
          show_non_blocking_message_dialog("this file has an error--please fix then hit ok: \n" + edl_path + "\n " + e)
          raise e
        end
      end
      EdlFilesChosen[dvd_id] ||= edl_path
      [drive_or_file, dvd_volume_name, dvd_id, edl_path, descriptors]
    end
    
    LocalStorage.set_default('mplayer_beginning_buffer', 0.5)

    def is_dvd? drive_or_file
      # it's like a/b/VIDEO_TS or d:/
      if File.basename(File.dirname(drive_or_file)) == 'VIDEO_TS' 
        # /a/b/c/VIDEO_TS/yo.vob
        true
      elsif File.exist?(drive_or_file + '/VIDEO_TS')
        # d:\
        true
      elsif OS.mac? && (drive_or_file =~ /\/dev\/rdisk\d+/)
        true
      else
       false
      end
    end

   def begin_buffer_preference
    LocalStorage['mplayer_beginning_buffer']
   end
    
    def play_smplayer_edl_non_blocking optional_file_with_edl_path = nil, extra_mplayer_commands_array = [], force_mplayer = false, start_full_screen = true, add_secs_end = 0, 
	    add_secs_begin = begin_buffer_preference, show_subs = false
      if we_are_in_create_mode
        assert(add_secs_begin == 0 && add_secs_end == 0)
      end
      if optional_file_with_edl_path
        drive_or_file, edl_path = optional_file_with_edl_path
        dvd_id = NonDvd # fake it out...LODO a bit smelly/ugly
      else
        drive_or_file, dvd_volume_name, dvd_id, edl_path, descriptors = choose_dvd_or_file_and_edl_for_it
      end
      start_add_this_to_all_ts = 0
	  
      if edl_path # some don't have one [?]
	    begin
		  # TODO combine these 2 methods yipzers
          descriptors = EdlParser.parse_file edl_path
  	      splits = [] # TODO not pass as parameter either
          edl_contents = MplayerEdl.convert_to_edl descriptors, add_secs_end, add_secs_begin, splits, start_add_this_to_all_ts # add a sec to mutes to accomodate for mplayer's oddness..
          File.write(EdlTempFile, edl_contents)
          extra_mplayer_commands_array << "-edl #{EdlTempFile}" 
		rescue SyntaxError => e
		  show_blocking_message_dialog "unable to parse file! #{edl_path} #{e}"
		  raise
		end
        title_track = get_title_track_string(descriptors)
      end
      
      if is_dvd?(drive_or_file)
        # it's a DVD of some sort
        extra_mplayer_commands_array << get_dvd_playback_options(descriptors)
      else
	    check_for_ffmpeg_installed
	    # it's a file
        # check if it has a start offset...
        all =  `ffmpeg -i "#{drive_or_file}" 2>&1` # => Duration: 01:35:49.59, start: 600.000000
        all =~ /Duration.*start: ([\d\.]+)/
        start = $1.to_f
        if start > 1 # LODO dvd's themselves start at 0.3 [sintel], but I don't think much higher than that never seen it...
          show_non_blocking_message_dialog "Warning: file seems to start at an extra offset, adding it to the timestamps... #{start}
            maybe not compatible with XBMC, if that's what you use, and you probably don't" # LODO test it XBMC...
          start_add_this_to_all_ts = start
        end
      end
      
      run_smplayer_non_blocking drive_or_file, title_track, extra_mplayer_commands_array.join(' '), force_mplayer, show_subs, start_full_screen, get_srt_filename(descriptors, edl_path)
    end
    
    def print *args
      Kernel.print *args # avoid bin\sensible-cinema.rb:83:in `system_blocking': cannot convert instance of class org.jruby.RubyString to class java.awt.Graphics (TypeError)
    end
    
    def open_file_to_edit_it filename, options = {} # :start_minimized is the only option
      if OS.windows?
        if options[:start_minimized]
          system_non_blocking "start /min notepad \"#{filename}\""
        else
          system_non_blocking "notepad \"#{filename}\""
        end
      else
        # ignore minimized :P
        system_non_blocking "open -a TextEdit \"#{filename}\""
      end
    end

    def show_message message
      SimpleGuiCreator.show_message message
    end
    
    def new_nonexisting_filechooser_and_go title = nil, default_dir = nil, default_file = nil
      bring_to_front unless OS.mac? # causes triplicate windows on mac! LODO rdp investigate
      SimpleGuiCreator.new_nonexisting_filechooser_and_go title, default_dir, default_file
    end

    # also caches directory previously selected ...
    def new_existing_file_selector_and_select_file title, dir = nil
      bring_to_front unless OS.mac? # causes same duplicate prompts?
      unique_trace = caller.inspect # or #hash I guess, but maybe easier for debugging purposes to save the whole trace
      p unique_trace
      if LocalStorage[unique_trace]
        dir = LocalStorage[unique_trace]
      end
      if $VERBOSE
        p 'using system default starting dir for finder, not seen before, not default specified' unless dir # happens more frequently after code changes alter the path :P
        p "using lookup dir #{dir} #{LocalStorage[unique_trace]}"
      end
      got = SimpleGuiCreator.new_previously_existing_file_selector_and_go title, dir
      LocalStorage[unique_trace] = File.dirname(got)
      got
    end
    
    def show_blocking_message_dialog(message, title = message.split("\n")[0], style= JOptionPane::INFORMATION_MESSAGE)
      SimpleGuiCreator.show_blocking_message_dialog message, title, style
    end
    
    # call dispose on this to close it if it hasn't been canceled yet...
    def show_non_blocking_message_dialog message, close_button_text = 'Close'
      bring_to_front
      # lodo NonBlockingDialog it can get to the top instead of being so buried...
      SimpleGuiCreator.show_non_blocking_message_dialog message, close_button_text
    end
    
    java_import javax.swing.UIManager

	def get_user_input_with_persistence(message, storage_key, cancel_ok=false)
	  got = get_user_input(message, LocalStorage[storage_key], cancel_ok)
      LocalStorage[storage_key] = got
	  got
	end
    def get_user_input(message, default = '', cancel_ok = false)
      SimpleGuiCreator.get_user_input message, default, cancel_ok
    end
    
    def show_copy_pastable_string(message, value)
      bring_to_front
      RubyClip.set_clipboard value            
      get_user_input message + " (has been copied to clipboard)", value, true
    end
    
    def show_in_explorer filename
      SimpleGuiCreator.show_in_explorer filename
    end
    
    def show_select_buttons_prompt message, names ={}
      SimpleGuiCreator.show_select_buttons_prompt(message, names)
    end

    def parse_edl path
      EdlParser.parse_file path
    end
    
    def get_freespace path
      JFile.new(File.dirname(path)).get_usable_space
    end    

    def get_drive_with_most_space_with_slash
      DriveInfo.get_drive_with_most_space_with_slash
    end
    
    attr_accessor :background_thread, :buttons
    
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
        names += ['No DVD mounted so click to choose a Local File (or insert DVD, then re-try)']
        used_local_file_option = true
      end
      
      count = 0
      opticals.each{|d| count += 1 if d.VolumeName}
      if count == 1 && !used_local_file_option
       # just choose it if there's only one disk available..
       p 'selecting only disk currently present in the various DVD drives [if you have more than one, that is]'
       selected_idx = opticals.index{|d| d.VolumeName}
       unless selected_idx
         show_blocking_message_dialog "Please insert a disk first"
         raise 'inset disk'
       end
      else
        dialog = get_disk_chooser_window names
        selected_idx = dialog.go_selected_index
      end
        if used_local_file_option
          raise unless selected_idx == 0 # it was our only option...they must have selected it!
          filename = new_existing_file_selector_and_select_file("Select yer previously grabbed from DVD file")
          return [filename, File.basename(filename), NonDvd]
        else
          disk = opticals[selected_idx]
          out = show_non_blocking_message_dialog "calculating current disk's unique id...if this pauses more than 10s then clean your DVD..."
          begin
		        dvd_id = DriveInfo.md5sum_disk(disk.MountPoint)
          rescue Exception => e
		        show_blocking_message_dialog e.to_s # todo a bit ugly...
			      raise
		      ensure
		      out.dispose
		      end
          @_choose_dvd_drive_or_file = [disk.DevicePoint, opticals[selected_idx].VolumeName, dvd_id]
          return @_choose_dvd_drive_or_file
        end
    end

    
    def display_and_raise error_message
      show_blocking_message_dialog error_message
      raise error_message
    end
    
    def with_autoclose_message(message)
      a = show_non_blocking_message_dialog message
	  begin
        yield
	  ensure
        a.close
	  end
    end
	
    def we_are_in_upconvert_mode
      @args.index("--upconvert-mode")
    end

    def setup_default_buttons
      if we_are_in_upconvert_mode
        add_play_upconvert_buttons
      else
        if we_are_in_create_mode
          setup_create_buttons
        elsif in_online_player_startup_mode
          setup_online_player_buttons
        else
          setup_normal_buttons
        end
      
      end # big else
      
      @exit = new_jbutton("Exit", "Exits the application and kills any background processes that are running at all--don't exit unless you are done processing all the way!")
      @exit.on_clicked {
        Thread.new { self.close } # don't waste the time to close it :P
        puts 'Thank you for using Sensible Cinema. Come again!'
      }

      increment_button_location
      increment_button_location
      self

    end

    def get_disk_chooser_window names
      DropDownSelector.new(self, names, "Click to select DVD drive")
    end
	
	def get_temp_file_name name_with_ext
	  File.dirname(EdlTempFile) + '/' + name_with_ext
	end
	
    # converts to full path, 8.3 if on doze
    def normalize_path path
      path = File.expand_path path
      path = EightThree.convert_path_to_8_3 path if OS.doze?
    end


  end
  
end


class ::File
      def self.get_root_dir this_path
        this_path = File.expand_path this_path
        if OS.doze?
          this_path[0..2]
        else
          this_path.split('/')[0]
        end
      end
      
      def self.strip_drive_windows this_complete_path
        if OS.doze?
          this_complete_path[2..-1]
        else
          this_complete_path
        end
      end
end

class ::String
 def just_letters
     gsub(/[^a-z0-9]/i, '').downcase
 end
end
