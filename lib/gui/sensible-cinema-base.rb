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
end

require_relative '../swing_helpers'

# attempt to load on demand...i.e. faster...
for kls in [:MencoderWrapper, :MplayerEdl, :PlayAudio, :SubtitleProfanityFinder, :ConvertThirtyFps, :RubyClip, :DriveInfo]
  autoload kls, "./lib/#{kls.to_s.snake_case}"
end

# a few I'll always need eventually...
require_relative '../storage'
require_relative '../edl_parser'
require 'tmpdir'
require 'whichr'
require 'os'
if OS.doze?
  autoload :WMI, 'ruby-wmi'
  autoload :EightThree, './lib/eight_three'
end

class String
 def to_filename
   if OS.windows?
     self.gsub('/', "\\")
   else
    self
  end
 end
end

if OS.windows?
  vendor_cache = File.expand_path(File.dirname(__FILE__)) + '/../vendor/cache'
  for name in ['.', 'mencoder', 'ffmpeg']
    # put them all before the old path
    ENV['PATH'] = (vendor_cache + '/' + name).to_filename + ';' + ENV['PATH']
  end
  
  installed_smplayer_folders = Dir['{c,d,e,f,g}:/program files*/MPlayer for Windows*'] # sometimes ends with UI? huh?

  for folder in installed_smplayer_folders
    ENV['PATH'] = ENV['PATH'] + ";#{folder.gsub('/', "\\")}"
  end

else
  ENV['PATH'] = ENV['PATH'] + ':' + '/opt/local/bin' # add macports' bin in, just in case...
end

import 'javax.swing.ImageIcon'
require_relative './sensible-cinema-dependencies'

module SensibleSwing
  VERSION = File.read(File.dirname(__FILE__) + "/../../VERSION").strip
  puts "v. " + VERSION
  
  UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()) # sigh
  
  class MainWindow < JFrame
    
    def initialize be_visible = true
      super "Sensible-Cinema #{VERSION} (GPL)"
      force_accept_license_first

      setDefaultCloseOperation JFrame::EXIT_ON_CLOSE # default is exit on close
      @panel = JPanel.new
      @buttons = []
      @panel.set_layout nil
      add @panel # why can't I just slap these down? panel? huh?
      @starting_button_y = 40
      @button_width = 400      
      
      add_text_line "Welcome to Sensible Cinema!"
      @starting_button_y += 10 # kinder ugly...
      add_text_line "      Rest mouse over buttons for \"help\" type descriptions (tooltips)."
      add_text_line ""
      
      setIconImage(ImageIcon.new(__DIR__ + "/../vendor/profs.png").getImage())
      check_for_various_dependencies
      set_visible be_visible
    end
    
    def we_are_in_create_mode
     ARGV.index("--create-mode")
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
    
    def force_accept_license_first
      if !(LocalStorage['main_license_accepted'] == VERSION)
        require_blocking_license_accept_dialog 'Sensible Cinema', 'gplv3', 'http://www.gnu.org/licenses/gpl.html', 'Sensible Cinema license agreement', 
            "Sensible Cinema is distributed under the gplv3 (http://www.gnu.org/licenses/gpl.html).\nBY CLICKING \"accept\" YOU SIGNIFY THAT YOU HAVE READ, UNDERSTOOD AND AGREED TO ABIDE BY THE TERMS OF THIS AGREEMENT"
        require_blocking_license_accept_dialog 'Sensible Cinema', 'is_it_legal_to_copy_dvds.txt file', File.expand_path(File.dirname(__FILE__) + "/../documentation/is_it_legal_to_copy_dvds.txt"), 
            'is_it_legal_to_copy_dvds.txt file', 'I acknowledge that I have read, understand, accept and agree to abide by the implications noted in the documentation/is_it_legal_to_copy_dvds.txt file'
        LocalStorage['main_license_accepted'] = VERSION
      end
    end

    LocalStorage = Storage.new("sensible_cinema_storage")
    
    def when_thread_done(thread)
      Thread.new {thread.join; yield }
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

    # a window that when closed doesn't bring the whole app down
    def new_child_window
      child = MainWindow.new
      child.setDefaultCloseOperation(JFrame::DISPOSE_ON_CLOSE)
      child.parent=self # this should have failed in the PPL
      # make both windows visible z-wise
      x, y = self.get_location.x, self.get_location.y
      child.set_location(x + 100, y + 100)
      child
    end
    
    def run_smplayer_non_blocking *args
      @background_thread = Thread.new {
        run_smplayer_blocking *args
      }
    end

    def run_smplayer_blocking play_this, title_track_maybe_nil, passed_in_extra_options, force_use_mplayer, show_subs
      unless File.exist?(File.expand_path(play_this))
        raise play_this + ' non existing?' # till these go away in mac :)
      end

      extra_options = ""
      # -framedrop is for slow CPU's
      # same with -autosync to try and help it stay in sync... -mc 0.03 is to A/V correct 1s audio per 2s video
      # -hardframedrop might help but hurts just too much
      extra_options << " -framedrop "      
      # ?? extra_mplayer_commands << "-mc 0.016" ??
      extra_options << " -autosync 15 " 
      
      unless show_subs
        # disable subtitles
        extra_options << " -nosub -noautosub -forcedsubsonly -sid 1000 "
      end
      extra_options << " -alang en "
      extra_options += " -slang en "

      parent_parent = File.basename(File.dirname(play_this))
      force_use_mplayer ||= OS.mac?
      if parent_parent == 'VIDEO_TS'
        # case d:\yo\VIDEO_TS\title0.vob
        dvd_device_dir = normalize_path(File.dirname(play_this))
        if force_use_mplayer
          extra_options += " -dvd-device \"#{dvd_device_dir}/..\""
        else 
          # smplayer
          raise if dvd_device_dir =~ / / && OS.mac? # not accomodated <sniff>
          extra_options += " -dvd-device #{dvd_device_dir}/.."
        end
        play_this = "dvdnav://#{title_track_maybe_nil}"
      elsif File.exist?(play_this + '/VIDEO_TS')
        # case d:\ where d:\VIDEO_TS exists [DVD mounted in drive] or mac's /Volumes/YO
        raise if play_this =~ / / # unexpected
        extra_options += " -nocache -dvd-device #{play_this}"
        play_this = "dvdnav://#{title_track_maybe_nil}"
      else
        # case g:\video\filename.mpg
        # leave it the same...
      end
      if play_this =~ /dvdnav/ && title_track_maybe_nil
        extra_options << " -msglevel identify=4 " # prevent smplayer from using *forever* to look up info on DVD's with -identify ...
      end
      
      start_full_screen = true
      
      extra_options += " -mouse-movements #{get_upconvert_secondary_settings} " # just in case smplayer also needs -mouse-movements... :) LODO
      extra_options += " -lavdopts threads=#{OS.cpu_count} " # just in case this helps [supposed to with h.264] # fast *crashes* doze...
      if force_use_mplayer
       show_mplayer_instructions_once
       conf_file = File.expand_path './mplayer_input_conf'
       File.write conf_file, "ENTER {dvdnav} dvdnav select\nMOUSE_BTN0 {dvdnav} dvdnav select\nMOUSE_BTN0_DBL vo_fullscreen\nMOUSE_BTN2 vo_fullscreen\nKP_ENTER dvdnav select\n" # that KP_ENTER doesn't actually work.  Nor the MOUSE_BTN0 on windows. Weird.
       extra_options += " -font #{File.expand_path('subfont.ttf')} "
       extra_options += " -volume 100 " # why start low? mplayer why oh why LODO
       if OS.windows?
        # direct3d for windows 7 old nvidia cards' sake [yipes] and also dvdnav sake
        extra_options += " -vo direct3d "
        conf_file = conf_file[2..-1] # strip off drive letter, which it doesn't seem to like no sir
       end
       extra_options += " -fs " if start_full_screen
      
       upconv = get_upconvert_vf_settings
       upconv = "-vf #{upconv}" if upconv.present?
       c = "mplayer #{extra_options} #{upconv} -input conf=\"#{conf_file}\" #{passed_in_extra_options} \"#{play_this}\" "
      else
        if OS.windows?
          extra_options += " -vo direct3d " # more light nvidia...should be ok...
        end
        set_smplayer_opts extra_options + " " + passed_in_extra_options, get_upconvert_vf_settings, show_subs
        c = "smplayer_portable \"#{play_this}\" -config-path \"#{File.dirname SMPlayerIniFile}\" " 
        c += " -fullscreen " if start_full_screen
        if !we_are_in_create_mode
          #c += " -close-at-end " # we're still too unstable, mate...
        end
      end
      puts c 
      system_blocking c
    end
    
    SMPlayerIniFile = File.expand_path("~/.smplayer/smplayer.ini")
    
    def set_smplayer_opts to_this, video_, show_subs = false
      p 'set smplayer extra opts to this:' + to_this
      old_prefs = File.read(SMPlayerIniFile) rescue ''
      unless old_prefs.length > 0
        # LODO double check the rest here...
        old_prefs = "[advanced]\nmplayer_additional_options=\nmplayer_additional_video_filters=\n[subtitles]\nautoload_sub=false\n[performance]\npriority=3" 
      end
      raise to_this if to_this =~ /"/ # unexpected, unfortunately... <smplayer bug>
      assert new_prefs = old_prefs.gsub(/mplayer_additional_options=.*/, "mplayer_additional_options=#{to_this}")
      assert new_prefs.gsub!(/autoload_sub=.*$/, "autoload_sub=#{show_subs.to_s}")
      raise if get_upconvert_vf_settings =~ /"/
      assert new_prefs.gsub!(/mplayer_additional_video_filters=.*$/, "mplayer_additional_video_filters=\"#{get_upconvert_vf_settings}\"")
      new_prefs.gsub!(/priority=.*$/, "priority=3") # normal priority...scary otherwise! lodo tell smplayer...
      # enable dvdnav navigation, just for kicks I guess.
      new_prefs.gsub!(/use_dvdnav=.*$/, "use_dvdnav=true")
      
      FileUtils.mkdir_p File.dirname(SMPlayerIniFile) # case it doesn't yet exist
      File.write(SMPlayerIniFile, new_prefs)
      new_prefs.each_line{|l| print l if l =~ /additional_video/} # debug
    end
    
    def create_brand_new_edl
      drive, volume, dvd_id = choose_dvd_drive_or_file true
      english_name = get_user_input("Enter a human readable DVD description for #{volume}", volume.gsub('_', ' ').downcase)
      input = <<-EOL
# comments can go after a # on any line, for example this one.
"name" => "#{english_name}",

"mutes" => [
  # an example line, uncomment the leading "#" to make it active
  # "0:00:01.0", "0:00:02.0", "profanity", "da..", 
],

"blank_outs" => [
  # an example line, uncomment the leading "#" to make it active
  # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
],

"volume_name" => "#{volume}",
"disk_unique_id" => "#{dvd_id}",
"dvd_title_track" => "1", # the "show DVD info" button will tell you title lengths (typically longest title is the title track)
# "dvd_title_track_length" => "9999", # sum length, on the DVD, use the show DVD info button to retrieve it.
# "opensubtitles_number" => "1234567",
# "not edited out stuff" => "some violence left in...",
# "closing thoughts" => "only did the...",
# "mplayer_dvd_splits" => ["59:59", "1:04:59"], # or [] if there are none.  Additive currently.  12345.6 ok. In mplayer, the DVD timestamp "resets" to zero for some reason, so you need to specify when if you want to use mplayer DVD realtime playback, or use mencoder -edl to split your file.  See http://goo.gl/yMfqX
        EOL
      # TODO auto-ify above, move docs to a file in documentation.
      filename = EdlParser::EDL_DIR + "/edls_being_edited/" + english_name.gsub(' ', '_') + '.txt'
      filename.downcase!
      File.write(filename, input) unless File.exist?(filename) # lodo let them choose name (?)
      open_file_to_edit_it filename
    end     
    
    def system_blocking command, low_prio = false
      return true if command =~ /^@rem/ # JRUBY-5890 bug
      if low_prio
        out = IO.popen(command) # + " 2>&1"
        low_prio = 64 # from msdn
        
        if command =~ /(ffmpeg|mencoder)/
          # XXXX not sure if there's a better way...because some *are* complex and have ampersands...
          # unfortunately have to check for nil because it could exit too early [?]
          exe_name = $1 + '.exe'
          begin
            p = proc{ ole = WMI::Win32_Process.find(:first,  :conditions => {'Name' => exe_name}); sleep 1 unless ole; ole }
            piddy = p.call || p.call || p.call # we actually do need this to loop...guess we're too quick
            # but the first time through this still inexplicably fails all 3...odd
            piddys = WMI::Win32_Process.find(:all,  :conditions => {'Name' => exe_name})
            for piddy in piddys
              # piddy.SetPriority low_prio # this call can seg fault at times...JRUBY-5422
              pid = piddy.ProcessId # this doesn't seg fault, tho
              system_original("vendor\\setpriority -lowest #{pid}") # uses PID for the command line
            end
          rescue Exception => e
            p 'warning, got exception trying to set priority [jruby prob? ...]', e
          end
        end
        print out.read # let it finish
        out.close
        $?.exitstatus == 0 # 0 means success
      else
        raise command + ' failed' unless system_original command
      end
    end
    
    def system_non_blocking command
      @background_thread = Thread.new { system_original command }
    end
    
    # make them choose which system call to use explicitly
    undef system
   
    def play_dvd_smplayer_unedited use_mplayer_instead, show_instructions, show_subs
      drive_or_file, dvd_volume_name, dvd_id, edl_path_maybe_nil, descriptors_maybe_nil = choose_dvd_or_file_and_edl_for_it false
      if descriptors_maybe_nil
        title_track_maybe_nil = get_title_track(descriptors_maybe_nil, false)
      end
      if show_instructions
        # want these even with smplayer sometimes I guess, if in power user mode anyway
        show_mplayer_instructions_once
      end
      run_smplayer_non_blocking drive_or_file, title_track_maybe_nil, "-osd-fractions 2", use_mplayer_instead, show_subs

    end

    if OS.doze? # avoids spaces in filenames :)
      EdlTempFile = EightThree.convert_path_to_8_3(Dir.tmpdir) + '\\mplayer.temp.edl'
    else
      raise if Dir.tmpdir =~ / / # that would be unexpected, and probably cause problems...
      EdlTempFile = Dir.tmpdir + '/mplayer.temp.edl'
    end
    
    def show_mplayer_instructions_once
      @_show_mplayer_instructions_once ||= show_non_blocking_message_dialog <<-EOL
        About to run mplayer.  To control it, use
        spacebar : pause,
        double clicky/right click : toggle full screen,
        arrow keys (left, right, up down, pg up, pg dn) to seek/scan
        / and *	: inc/dec volume.
        'o' key: turn on on-screen-display timestamps (note: the OSD timestamps [upper left] are 30 fps so will need to be converted to use).
        'v' key: turn off subtitles.
        '.' key: step one frame.
         # key: change audio language track
      EOL
    end
    
    MplayerBeginingBuffer = 1.0
    MplayerEndBuffer = 0.0
    
    def play_mplayer_edl_non_blocking optional_file_with_edl_path = nil, extra_mplayer_commands_array = [], force_mplayer = false
      if optional_file_with_edl_path
        drive_or_file, edl_path = optional_file_with_edl_path
        dvd_id = NonDvd # fake it out...LODO a bit smelly
      else
        drive_or_file, dvd_volume_name, dvd_id, edl_path, descriptors = choose_dvd_or_file_and_edl_for_it
      end
      start_add_this_to_all_ts = 0
      if edl_path # some don't care...
        descriptors = EdlParser.parse_file edl_path
        title_track = get_title_track(descriptors)
        splits = descriptors['mplayer_dvd_splits']
      end
      
      if dvd_id == NonDvd && !(File.basename(File.dirname(drive_or_file)) == 'VIDEO_TS') # VOB's...always start at 0
        # check if starts offset...
        all =  `ffmpeg -i "#{drive_or_file}" 2>&1`
        # Duration: 01:35:49.59, start: 600.000000
        all =~ /Duration.*start: ([\d\.]+)/
        start = $1.to_f
        if start > 1 # LODO huh? dvd's themselves start at 0.3 [sintel]?
          show_non_blocking_message_dialog "Warning: file seems to start at an extra offset, adding it to the timestamps... #{start}
            maybe not compatible with XBMC, if that's what you use, and you probably don't" # TODO test it XBMC...
          start_add_this_to_all_ts = start
        end
        splits = []
      else
        if splits == nil
          show_blocking_message_dialog("warning: edit list does not contain mplayer replay information [mplayer_dvd_splits] so edits past a certain time period might not won't work ( http://goo.gl/yMfqX ).")
          splits = []
        end
      end
      
      if edl_path
        splits.map!{|s|  EdlParser.translate_string_to_seconds(s) }
        edl_contents = MplayerEdl.convert_to_edl descriptors, add_secs_end = MplayerEndBuffer, add_secs_begin = MplayerBeginingBuffer, splits, start_add_this_to_all_ts # add a sec to mutes to accomodate for mplayer's oddness..
        File.write(EdlTempFile, edl_contents)
        extra_mplayer_commands_array << "-edl #{File.expand_path EdlTempFile}" 
      end
      
      run_smplayer_non_blocking drive_or_file, title_track, extra_mplayer_commands_array.join(' '), force_mplayer, false
    end
    
    def assert_ownership_dialog 
      message = "Do you certify you own the DVD this came of and have it in your possession?"
      title = "Verify ownership"
      returned = JOptionPane.showConfirmDialog self, message, title, JOptionPane::YES_NO_CANCEL_OPTION
      assert_confirmed_dialog returned, nil
    end
    
    # returns 0,1,2 for yes, no, cancel equivs
    def show_select_buttons_prompt message, names_hash
      old = ['no', 'yes', 'ok'].map{|name| 'OptionPane.' + name + 'ButtonText'}.map{|name| [name, UIManager.get(name)]}
      if names_hash[:yes]
        UIManager.put("OptionPane.yesButtonText", names_hash[:yes])
      end
      if names_hash[:no]
        UIManager.put("OptionPane.noButtonText", names_hash[:no])
      end
      # if names_hash[:ok] # ???
      #   UIManager.put("OptionPane.okButtonText", names_hash[:ok])
      # end
      if names_hash[:cancel]
        UIManager.put("OptionPane.noButtonText", names_hash[:cancel])
      end
      returned = JOptionPane.showConfirmDialog self, message, title, JOptionPane::YES_NO_CANCEL_OPTION
      old.each{|name, old_setting| UIManager.put(name, old_setting)}
      returned
    end
      
    def require_blocking_license_accept_dialog program, license_name, license_url_should_also_be_embedded_by_you_in_message, 
      title = 'Confirm Acceptance of License Agreement', message = nil
      puts 'Please confirm license agreement in open window.'
      # cancel button stays the same...
      
      message ||= "Sensible Cinema requires a separately installed program (#{program}), not yet installed.
        You can install this program manually to the vendor/cache subdirectory, or Sensible Cinema can download it for you.
        By clicking accept, below, you are confirming that you have read and agree to be bound by the
        terms of its license (the #{license_name}), located at #{license_url_should_also_be_embedded_by_you_in_message}.  
        Click 'View License' to view it.  If you do not agree to these terms, click 'Cancel'.  You also agree that this is a 
        separate program, with its own distribution, license, ownership and copyright.  
        You agree that you are responsible for the download and use of this program, within sensible cinema or otherwise."
      returned = show_select_buttons_prompt message, :yes => 'Accept', :no => "View #{license_name}"
      assert_confirmed_dialog returned, license_url_should_also_be_embedded_by_you_in_message
      p 'confirmation of sensible cinema related license saved of: ' + license_name
      throw unless returned == 0
      
    end
    
    def assert_confirmed_dialog returned, license_url_should_also_be_embedded_by_you_in_message
      # 1 is view button was clicked
      # 0 is accept
      # 2 is cancel
      if returned == 1
        if license_url_should_also_be_embedded_by_you_in_message
          system_non_blocking("start #{license_url_should_also_be_embedded_by_you_in_message}")
          puts "Please restart after reading license agreement, to be able to then accept it."
        end
        System.exit 0
      end
      if returned == 2
        p 'license not accepted...exiting'
        System.exit 1
      end
      if returned == -1
        p 'license exited early...exiting'
        System.exit 1
      end
    end
    
    def print *args
      Kernel.print *args # avoid bin\sensible-cinema.rb:83:in `system_blocking': cannot convert instance of class org.jruby.RubyString to class java.awt.Graphics (TypeError)
    end
    
    def download_7zip
      Dir.mkdir('./vendor/cache') unless File.directory? 'vendor/cache' # development may not have it created yet... [?]
      unless File.exist? 'vendor/cache/7za.exe'
        Dir.chdir('vendor/cache') do
          print 'downloading unzipper (7zip--400K) ...'
          MainWindow.download("http://downloads.sourceforge.net/project/sevenzip/7-Zip/9.20/7za920.zip", "7za920.zip")
          system_blocking("../unzip.exe -o 7za920.zip") # -o means "overwrite" without prompting
        end
      end
    end
    
    def download_zip_file_and_extract english_name, url, to_this
      download_7zip
      Dir.chdir('vendor/cache') do
        file_name = url.split('/')[-1]
        print "downloading #{english_name} ..."
        MainWindow.download(url, file_name)
        system_blocking("7za e #{file_name} -y -o#{to_this}")
        puts 'done ' + english_name
        # creates vendor/cache/mencoder/mencoder.exe...
      end
    end
    
    def check_for_exe windows_full_loc, unix_name
      # in windows, that exe *at that location* must exist...
      if OS.windows?
        File.exist?(windows_full_loc)
      else
        require 'lib/check_installed_mac.rb'
        if !CheckInstalledMac.check_for_installed(unix_name)
          exit 1 # it'll have already displayed a message...
        else
          true
        end
      end
    end
    
    def check_for_various_dependencies
      if we_are_in_create_mode        
        if !check_for_exe('vendor/cache/mencoder/mencoder.exe', 'mencoder')
          require_blocking_license_accept_dialog 'mplayer', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: mplayer with mencoder."
          download_zip_file_and_extract "Mplayer/mencoder (6MB)", "http://sourceforge.net/projects/mplayer-win32/files/MPlayer%20and%20MEncoder/revision%2033883/MPlayer-rtm-svn-33883.7z", "mencoder"
        end
      end

      # runtime dependencies, at least as of today...
      ffmpeg_exe_loc = File.expand_path('vendor/cache/ffmpeg/ffmpeg.exe')
      if !check_for_exe(ffmpeg_exe_loc, 'ffmpeg')
        require_blocking_license_accept_dialog 'ffmpeg', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: ffmpeg."
        download_zip_file_and_extract "ffmpeg (5MB)", "http://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-git-335bbe4-win32-static.7z", "ffmpeg"
      end
      if OS.mac?
        check_for_exe("mplayer", "mplayer") # mencoder and mplayer are separate for mac... [this checks for mac's mplayerx, too]
      else      
        path = RubyWhich.new.which('smplayer_portable')
        if(path.length == 0)
          # this one has its own installer...
          show_blocking_message_dialog("It appears that you need to install a pre-requisite dependency: MPlayer for Windows (MPUI).
          Click ok to be directed to its download website, where you can download and install it (recommend: MPUI....Full-Package.exe), 
          then restart sensible cinema.  NB that it takes awhile to install.  Sorry about that.", 
          "Lacking dependency", JOptionPane::ERROR_MESSAGE)
          open_url_to_view_it_non_blocking "http://code.google.com/p/mulder/downloads/list?can=2&q=MPlayer&sort=-uploaded&colspec=Filename%20Summary%20Type%20Uploaded%20Size%20DownloadCount"
          System.exit 0
        end
      end
    end
    
    def open_url_to_view_it_non_blocking url
      if OS.windows?
        system_non_blocking("start #{url.gsub('&', '^&')}") # LODO would launchy help/work here with the full url?
      else
        system_non_blocking "#{OS.open_file_command} \"#{url}\"" # LODO test
      end
    end
    
    def open_file_to_edit_it filename, start_minimized=false
      if OS.windows?
        if start_minimized
          system_non_blocking "start /min notepad \"#{filename}\""
        else
          system_non_blocking "notepad \"#{filename}\""
        end
      else
        system_non_blocking "open -a TextEdit \"#{filename}\""
      end
    end
    
    def new_nonexisting_filechooser title = nil, default_dir = nil
      out = JFileChooser.new
      out.set_title title
      if default_dir
        out.set_current_directory JFile.new(default_dir)
      end
      out
    end

    def show_blocking_message_dialog(message, title = message.split("\n")[0], style= JOptionPane::INFORMATION_MESSAGE)
      JOptionPane.showMessageDialog(nil, message, title, style)
      true
    end
    
    # call dispose on this to close it if it hasn't been canceled yet...
    def show_non_blocking_message_dialog message, close_button_text = 'Close'
      # lodo NonBlockingDialog it can get to the top instead of being so buried...
      NonBlockingDialog.new(message, close_button_text)
    end
    
    include_class javax.swing.UIManager
    
    def get_user_input(message, default = '', cancel_ok = false)
      received = JOptionPane.showInputDialog(message, default)
      unless cancel_ok
        raise 'user cancelled' unless received
      end
      received
    end
    
    def show_copy_pastable_string(message, value)
      RubyClip.set_clipboard value            
      get_user_input message + " (has been copied to clipboard)", value, true
    end
    
    
    def new_existing_file_selector_and_select_file title, dir=nil
      out = FileDialog.new(self, title, FileDialog::LOAD)
      out.set_title title
      dir ||= LocalStorage[caller.inspect]
      out.set_directory dir.to_filename if dir
      got = out.go
      raise 'cancelled choosing existing file method' unless got # I think we always want to raise...
      LocalStorage[caller.inspect] = File.dirname(got)
      got
    end
    
    
    # reveals My Documents if file/folder doesn't exist
    def show_in_explorer filename
      begin
        c = "explorer /e,/select,\"#{File.expand_path(filename).to_filename}\"" # command returns immediately...
        system_blocking c
      rescue => why_does_this_happen_ignore_this_exception_it_probably_actually_succeeded
      end
    end
    
    def get_disk_chooser_window names
      GetDisk.new(self, names)
    end
    

  end

  class GetDisk < JDialog
    attr_reader :selected_idx
    def initialize parent, options_array
      super parent, true

      box = JComboBox.new
      box.add_action_listener do |e|
        idx = box.get_selected_index
        if idx != 0
          # don't count choosing the first as a real entry
          @selected_idx = box.get_selected_index - 1
          dispose
        end
      end

      box.add_item "Click to select DVD drive" # put something in index 0
      options_array.each{|drive|
        box.add_item drive
      }
      add box
      pack # how do you get this arbitrary size? what the...
    end
  end
end

# LODO move to sane :) also remove the andand dep.
class String
  def present?
    length > 0
  end
end

class NilClass
  def present?
    false
  end
end
class Object
  def present?
    true
  end
end

class Array
  def present?
    length > 0
  end
end

# icon derived from: http://www.threes.com/index.php?option=com_content&view=article&id=1800:three-wise-monkeys&catid=82:mythology&Itemid=62
