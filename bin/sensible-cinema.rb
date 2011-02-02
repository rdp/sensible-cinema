#!/usr/bin/ruby # so my editor will like it...
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

print 'Loading Sensible Cinema...'
require File.expand_path(File.dirname(__FILE__) + "/../lib/add_any_bundled_gems_to_load_path.rb")
require 'sane' # failure here means you haven't bundled your dependencies...[rake task]

require_relative '../lib/mencoder_wrapper'
require_relative '../lib/storage'
require_relative '../lib/edl_parser'
require_relative '../lib/mplayer_edl'
require_relative '../lib/play_audio'

require 'tmpdir'
require_relative '../lib/swing_helpers'
require_relative '../lib/drive_info'
require 'whichr'
require 'ruby-wmi'

# must put mencoder first, as it has a working mplayer.exe in it...
vendor = File.expand_path(File.dirname(__FILE__)) + '/../vendor'
# XX do we need to_filename though?
ENV['PATH'] = ENV['PATH'] + ';' + (vendor + '/cache/mencoder').to_filename + ';' + (vendor + '/cache').to_filename

for drive in ['c', 'd', 'e']
  ENV['PATH'] = ENV['PATH'] + ";#{drive}:\\Program Files\\SMPlayer;#{drive}"
end

import 'javax.swing.ImageIcon'

module SensibleSwing
  VERSION = File.read(File.dirname(__FILE__) + "/../VERSION").strip
  puts "v. " + VERSION
  
  class MainWindow < JFrame

    def new_jbutton title, only_on_create_mode, always_add = false
      button = JButton.new title
      button.set_bounds(44, @starting_button_y, @button_width, 23)
      
      if ARGV.index("--create-mode")
        always_add = true if only_on_create_mode
      else
        always_add = true if !only_on_create_mode
      end
         
      if always_add
        increment_button_location
        @panel.add button
        @buttons << button
      end
      button
    end
    
    def increment_button_location
      @starting_button_y += 30
    end

    Storage = Storage.new("sc")
   
    
    def initialize
      super "Sensible-Cinema #{VERSION} (GPL)"
      if !(Storage['main_license_accepted'] == VERSION)
        show_blocking_license_accept_dialog 'Sensible Cinema', 'gplv3', 'http://www.gnu.org/licenses/gpl.html'
        show_blocking_license_accept_dialog 'Sensible Cinema', 'LICENSE.TXT file', File.expand_path(File.dirname(__FILE__) + "/../LICENSE.TXT"), 'LICENSE.TXT file', 'I acknowledge that I have read the LICENSE.TXT file.'
        Storage['main_license_accepted'] = VERSION
      end

      setDefaultCloseOperation JFrame::EXIT_ON_CLOSE
      panel = JPanel.new
      @panel = panel
      @buttons = []
      panel.set_layout nil
      add panel # why can't I just slap these down?

      jlabel = JLabel.new 'Welcome to Sensible Cinema!'
      happy = Font.new("Tahoma", Font::PLAIN, 11)
      jlabel.setFont(happy)
      jlabel.set_bounds(44,44,160,14)
      panel.add jlabel
      @starting_button_y = 120
      @button_width = 400

      @create = new_jbutton( "Create edited copy of DVD on Your Hard Drive, from a DVD", false )
      @create.on_clicked {
        do_copy_dvd_to_hard_drive false
      }
      
      @mplayer_edl = new_jbutton( "Watch DVD on computer edited realtime", false, true )
      @mplayer_edl.on_clicked {
        do_mplayer_edl
      }
      
      @watch_created_file = new_jbutton( "Watch edited copy of DVD", false).on_clicked {
        raise 'todo'
      }

      @watch_unedited = new_jbutton("Watch DVD unedited (while also grabbing to hard drive--saves overall time)", true) # if you have a fast enough cpu, that is
      @watch_unedited.on_clicked {
        success_no_run, wrote_to_here_fulli = do_copy_dvd_to_hard_drive false, true, true
        sleep 5 unless success_no_run
        command = "smplayer #{wrote_to_here_fulli}"
        system_non_blocking command
      }

      @preview_section = new_jbutton( "Preview a certain time frame (edited)", true )
      @preview_section.on_clicked {
        do_copy_dvd_to_hard_drive true
      }
      
      @preview_section_unedited = new_jbutton("Preview a certain time frame (unedited)", true)
      @preview_section_unedited.on_clicked {
        do_copy_dvd_to_hard_drive true, false, true
      }

      @rerun_preview = new_jbutton( "Re-run most recently watched preview time frame", true )
      @rerun_preview.on_clicked {
        repeat_last_copy_dvd_to_hard_drive
      }
      
      @fast_preview = new_jbutton( "preview (fast mode)", true).on_clicked {
        success, wrote_to_here_fulli = do_copy_dvd_to_hard_drive false, true
        sleep 0.5 # lodo take out ???
        background_thread.join if background_thread # let it write out the original fulli, if necessary [?]
        nice_file = wrote_to_here_fulli #+ ".fast.mpg"
        if false#!File.exist?(nice_file)
          p = NonBlockingDialog.new("Creating quick lookup file--NB that for each changed deletion, 
          you'll need to restart the fast preview SMplayer
          Also note that the start and end times will be slightly off if reality [delayed]
          Also note that while doing fast preview, it can be doing a normal preview as well
          in the background, simultaneously.")
          unless system_blocking("ffmpeg -i #{wrote_to_here_fulli} -target ntsc-dvd #{nice_file}")
            File.delete nice_file
            raise 'create ' 
          end
          p.dispose # it will be active for sure
        end
        smplayer_prefs_file = File.expand_path("~/.smplayer/smplayer.ini")
        old_prefs = File.read(smplayer_prefs_file) rescue ''
        new_prefs = old_prefs.gsub(/mplayer_additional_options=.*/, "mplayer_additional_options=-edl #{EdlTempFile}")
        File.write(smplayer_prefs_file, new_prefs)
        thread = do_mplayer_edl( "smplayer #{nice_file}") # note the smplayer, but it's for the fast file...
        Thread.new { # XXX do we need this?
          begin
            thread.join
          ensure
            File.write(smplayer_prefs_file, old_prefs)
          end
        }
      }

      @open_list = new_jbutton("Open/Edit a Delete List", true)
      @open_list.on_clicked {
        dialog = FileDialog.new(self, "Pick file to edit")
        dialog.set_directory EDL_DIR
        filename = dialog.go
        open_file_to_edit_it filename if filename
      }

      @create_new_edl_for_current_dvd = new_jbutton("Create new Delete List for a DVD", true)
      @create_new_edl_for_current_dvd.on_clicked do
        create_brand_new_edl
      end

      @display_unique = new_jbutton( "Display a DVD's unique ID", true ).on_clicked {
        drive, volume, md5 = choose_dvd_drive
        # display it, allow them to copy and paste it out
        get_user_input("#{drive} #{volume} for your copying+pasting pleasure (highlight, then ctrl+c to copy)        \n
        This is USED to identify a disk to match it to its EDL, later.", "\"disk_unique_id\" => \"#{md5}\",")
      }
      
      @upload = new_jbutton( "Upload/E-mail suggestion/Submit anything", true).on_clicked {
        system_non_blocking("start mailto:sensible-cinema@googlegroups.com")
        system_non_blocking("start http://groups.google.com/group/sensible-cinema")
      }
      
      @play_smplayer = new_jbutton( "Play DVD unedited (smplayer)", true).on_clicked {
        play_dvd_smplayer_unedited
      }
      
      @progress_bar = JProgressBar.new(0, 100)
      @progress_bar.set_bounds(44,@starting_button_y,@button_width,23)
      @progress_bar.visible = false
      panel.add @progress_bar

      increment_button_location
      increment_button_location

      @exit = new_jbutton("Exit", false, true).on_clicked {
        self.close
      }

      increment_button_location
      increment_button_location

      setSize @button_width+80, @starting_button_y
      setIconImage(ImageIcon.new(__dir__ + "/monkey.png").getImage())
      check_for_dependencies
    end
    
    def create_brand_new_edl
        drive, volume, md5 = choose_dvd_drive
        name = get_user_input("Enter DVD name for #{volume}")
        input = <<-EOL
# comments can go after a # on any line, for example this one.

"mutes" => [
  "0:00:01.0", "0:00:02.0", "profanity", "da..",
],

"blank_outs" => [
  "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
],

"name" => "#{name}",
"disk_unique_id" => "#{md5}",

# "dvd_title_track" => "1", # most DVD's use title 1. Not all do, though.  If sensible-cinema plays anything except the main title (for example, a trailer), when you use it, see http://goo.gl/QHLIF to set this field right.
# "not edited out stuff" => "some violence",
# "closing thoughts" => "still a fairly dark movie, overall",
# "mplayer_dvd_splits" => ["59:59", "1:04:59"], # these are where, in mplayer, the DVD timestamp "resets" to zero for whatever reason.  See http://goo.gl/yMfqX
        EOL
        filename = EDL_DIR + "\\" + name.gsub(' ', '_') + '.txt'
        filename.downcase!
        File.write(filename, input) unless File.exist?(filename) # lodo let them choose name (?)
        open_file_to_edit_it filename
      end

     
    alias system_original system
    
    def system_blocking command, low_prio = false
      if low_prio
        return if command =~ /^@rem/
        # man jruby+windows does not make this easy on me...
        out = IO.popen(command) # + " 2>&1"
        low_prio = 64
        
        if command =~ /(ffmpeg|mencoder)/
          # XXXX not sure if there's a better way...because some have ampersands...
          # unfortunately have to check for nil because it could exit too early [?]
          exe_name = $1 + '.exe'
          begin
          p = proc{ ole = WMI::Win32_Process.find(:first,  :conditions => {'Name' => exe_name}); sleep 1 unless ole; ole }
          piddy = p.call || p.call || p.call # we actually do need this to loop...guess we're too quick
          # but the first one still inexplicably fails always... LODO
          if piddy
            # piddy.SetPriority low_prio # this can seg fault...yikes...
            pid = piddy.ProcessId # this doesn't seg fault, tho
            system_original("vendor\\setpriority -lowest #{pid}") # be able to use the PID on the command line
          else
            # XXXX first one always fails [?] huh?
            p 'unable to find to set priority ' + exe_name
          end
          rescue Exception => e
            p 'warning, got exception trying to set PID [jruby...]', e
          end
        end
        print out.read # let it finish
        out.close
        $?.exitstatus == 0 # 0 means success
      else
        system_original command
      end
    end
    
    def system_non_blocking command
     Thread.new { system_original command }
    end
    
    # make them choose which system call to use explicitly
    undef system
    
    def download full_url, to_here
      require 'open-uri'
      writeOut = open(to_here, "wb")
      writeOut.write(open(full_url).read)
      writeOut.close
    end
    
    def play_dvd_smplayer_unedited
      drive, dvd_volume_name, md5sum, edl_path, descriptors = choose_dvd_and_edl_for_it
      title_track = get_title_track(descriptors)
      command =  "smplayer dvdnav://#{title_track} -dvd-device #{drive}"
      p command
      system_non_blocking command
    end

    EdlTempFile = Dir.tmpdir + '/mplayer.temp.edl'
    
    def do_mplayer_edl play_this_mplayer = nil, add_secs_end = 0, add_secs_beginning = 0.5
      drive, dvd_volume_name, md5sum, edl_path, descriptors = choose_dvd_and_edl_for_it
      descriptors = EdlParser.parse_file edl_path
      splits = descriptors['mplayer_dvd_splits']
      if splits == nil && !play_this_mplayer
        # don't display warning if they are watching the .fast file, since it doesn't need these
        if !play_this_mplayer
          show_blocking_message_dialog("warning: delete list does not contain mplayer replay information [mplayer_dvd_splits] so edits past a certain time period might not won't work ( http://goo.gl/yMfqX ).")
        end
        splits = []
      end
      splits.map!{|s|  EdlParser.translate_string_to_seconds(s) }
      edl_contents = MplayerEdl.convert_to_edl descriptors, add_secs_end, add_secs_beginning, splits # add a sec to mutes to accomodate for mplayer's oddness...
      File.write(EdlTempFile, edl_contents)
      title_track = get_title_track(descriptors)
      # oh the insanity of the console UI...LODO more user friendly player
      @popup ||= NonBlockingDialog.new("Running mplayer.  To control it, use space for pause.\n
      Also right and left arrows to seek, F key for full screen, [, ] to control playback speed.
      q or escape to quit.")
      # LODO dry up mplayer dvd opts...
      play_this_mplayer ||= "mplayer dvd://#{title_track}"
      command =  "#{play_this_mplayer} -nocache -alang en -sid 1000 -edl #{File.expand_path EdlTempFile} -dvd-device #{drive}"
      p command
      Thread.new { system_blocking command; @popup.dispose }
    end
      
    def show_blocking_license_accept_dialog program, license_name, license_url_should_also_be_embedded_by_you_in_message, title = 'Confirm Acceptance of License Agreement', message = nil
      puts 'Please confirm license agreement in open window'
      old = ['no', 'yes', 'ok'].map{|name| 'OptionPane.' + name + 'ButtonText'}.map{|name| [name, UIManager.get(name)]}
      UIManager.put("OptionPane.yesButtonText", 'Accept')
      UIManager.put("OptionPane.noButtonText", 'View License')
      # cancel button stays the same...
      
      message ||= "By clicking accept, below, you are agreeing to the license agreement for #{program} (the #{license_name}),
      located at #{license_url_should_also_be_embedded_by_you_in_message}.
      Click 'View License' to view it on your local machine."
      
      returned = JOptionPane.showConfirmDialog nil, message, title, JOptionPane::YES_NO_CANCEL_OPTION
      # 1 is view
      # 0 is accept
      # 2 is cancel
      if returned == 1
        system_non_blocking("start #{license_url_should_also_be_embedded_by_you_in_message}")
        System.exit 1
      end
      if returned == 2
        p 'license not accepted...'
        System.exit 1
      end
      if returned == -1
        p 'license exited early...'
        System.exit 1
      end
      throw unless returned == 0
      old.each{|name, old_setting| UIManager.put(name, old_setting)}
    end
    
    def print *args
      Kernel.print *args # avoid bin\sensible-cinema.rb:83:in `system_blocking': cannot convert instance of class org.jruby.RubyString to class java.awt.Graphics (TypeError)
    end
    
    def check_for_dependencies
      ffmpeg = RubyWhich.new.which('ffmpeg')
      if ffmpeg.length == 0
        show_blocking_message_dialog(self, "It appears that you need to install a dependency: imagemagick.\n
        Click ok to be directed to its download website.\nYou'll probably want to download and install the \"windows-dll.exe\" package.\n
        Then restart Sensible-Cinema.", "Lacking dependency", JOptionPane::ERROR_MESSAGE)
        system_non_blocking("start http://www.imagemagick.org/script/binary-releases.php#windows")
        java.lang.System.exit(1)
      end
      
      mencoder = RubyWhich.new.which('mencoder')
      if mencoder.length == 0
        show_blocking_license_accept_dialog 'MPlayer', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: mencoder."
        vendor_cache = File.expand_path(File.dirname(__FILE__)) + "/../vendor/cache/"
        ENV['PATH'] = ENV['PATH'] + ';' + vendor_cache + '\\..;' + vendor_cache
        Dir.chdir(vendor_cache) do
          print 'downloading unzipper...'
          download("http://downloads.sourceforge.net/project/sevenzip/7-Zip/9.20/7za920.zip", "7za920.zip")
          system_blocking("unzip -o 7za920.zip") # -o means "overwrite" without prompting
          # now we have 7za.exe
          print 'downloading mencoder.7z (6MB) ...'
          download("http://downloads.sourceforge.net/project/mplayer-win32/MPlayer%20and%20MEncoder/revision%2032492/MPlayer-rtm-svn-32492.7z", "mencoder.7z")
          system_blocking("7za e mencoder.7z -y -omencoder")
          puts 'done'
        end
      end
      
      if ARGV.index('--create-mode')
        # they're going to want these dependencies
        path = RubyWhich.new.which('smplayer')
        if(path.length == 0)
          # this one has its own license...
          show_blocking_message_dialog("It appears that you need to install a dependency: SMPlayer.\n
          Click ok to be directed to its download website, where you can download and install it, then restart sensible cinema.", 
          "Lacking dependency", JOptionPane::ERROR_MESSAGE)
          system_non_blocking("start http://smplayer.sourceforge.net/downloads.php")
          System.exit(1)
        end
      end
    end

    def open_file_to_edit_it filename
      system_non_blocking "notepad \"#{filename}\""
    end

    def single_edit_list_matches_dvd md5
      return unless md5 # ignore nil searches, where it wasn't set in the .txt file
      matching =  Dir[EDL_DIR + '/*.txt'].select{|file|
        begin
          parse_edl(file)["disk_unique_id"] == md5
        rescue SyntaxError
         # ignore poorly formed delete lists for auto choose
        end
      }
      if matching.length == 1
        file = matching[0]
        p "selecting the one matching file #{file} #{md5}"
        file
      else
        nil
      end
    end

    EDL_DIR = File.expand_path(__dir__  + "/../zamples/edit_decision_lists/dvds").to_filename

    def repeat_last_copy_dvd_to_hard_drive
      generate_and_run_bat_file *Storage['last_params']
    end

    def new_filechooser
      JFileChooser.new
    end

    def show_blocking_message_dialog(message, title = message.split("\n")[0], style= JOptionPane::INFORMATION_MESSAGE)
      JOptionPane.showMessageDialog(nil, message, title, style)
      true
    end
    
    include_class javax.swing.UIManager
    def get_user_input(message, default = '')
      start_time = JOptionPane.showInputDialog(message, default)
    end
    
    def parse_edl path
      EdlParser.parse_file path
    end
    
    def get_freespace path
      JFile.new(File.dirname(path)).get_usable_space
    end
    
    def choose_dvd_and_edl_for_it
      drive, dvd_volume_name, md5sum = choose_dvd_drive
      @_edit_list_path ||= 
      begin
        puts "#{drive}, #{dvd_volume_name}, #{md5sum}"
        edit_list_path = single_edit_list_matches_dvd(md5sum)
        if !edit_list_path
          fc = FileDialog.new(self)
          fc.set_title "Please pick a DVD Delete List File (non matching found)"
          fc.set_directory EDL_DIR
          edit_list_path = fc.go
        end
        raise 'cancelled' unless edit_list_path
        edit_list_path
      end
      
      # reload it just in case it has changed on disk
      descriptors = nil
      while(!descriptors)
          begin
            descriptors = parse_edl @_edit_list_path
          rescue SyntaxError => e
            puts e
            show_blocking_message_dialog("your file has an error--please fix then hit ok: \n" + @_edit_list_path + "\n " + e)
          end
      end
      [drive, dvd_volume_name, md5sum, @_edit_list_path, descriptors]
    end
    
    def get_title_track descriptors
      descriptors["dvd_title_track"] || "1"
    end
    
    def get_save_to_filename dvd_title
      @_get_save_to_filename ||=
      begin
        fc = new_filechooser
        fc.set_title "Pick where to save #{dvd_title} edited to"
        save_to_file_name = dvd_title + ' edited version'
        save_to_file_name = save_to_file_name.gsub(' ', '_').gsub( /\W/, '') # no punctuation or spaces for now...
        fc.set_file(get_drive_with_most_space_with_slash + save_to_file_name)
        save_to = fc.go
        a = File.open(File.dirname(save_to) + "/test_file_to_see_if_we_have_permission_to_write_to_this_folder", "w")
        a.close
        File.delete a.path
        freespace = get_freespace(save_to)
        if freespace < 16_000_000_000
          show_blocking_message_dialog("Warning: there may not be enough space on the disk for #{save_to} 
          (depending on DVD size, you may need like 16G free, but typically will need around 10GB free--you have #{freespace/1_000_000_000}GB free).  Click OK to continue.")
        end
        raise 'cannot save to filname with spaces yet (ask for it)' if save_to =~ / /
        save_to
      end
    end

    def do_copy_dvd_to_hard_drive should_prompt_for_start_and_end_times, exit_early_if_fulli_exists = false, watch_unedited = false
      drive, dvd_volume_name, md5sum, edit_list_path, descriptors = choose_dvd_and_edl_for_it
      
      descriptors = parse_edl(edit_list_path)
      if watch_unedited
        descriptors['mutes'] = descriptors['blank_outs'] = []
      end
      
      # LODO allow for spaces in the save_to filename
      if should_prompt_for_start_and_end_times
        # only show this message once :)
        @show_block ||= show_blocking_message_dialog("Ok, let's preview just a portion of it. \nNote that you'll want to preview a section that wholly includes a deleted section in it\n For example, if it mutes from second 1 to second 10, you'll want to play from 00:00 to 00:12 or what not.\nAlso note that the first time you preview a section of a video, it will take a long time as it sets up the video for previewing.\nSubsequent previews will be faster, though, as long as you use the same filename.\n
        Also note that if you change your delete list, you'll need to close, and regenerate the video to see it with your new settings.", "Preview")
        old_start = Storage['start_time']
        start_time = get_user_input("At what point in the video would you like to start your preview? (like 01:00 for starting at 1 minute)", Storage['start_time'])
        default_end = Storage['end_time']
        if start_time and start_time != old_start
          default_end = EdlParser.translate_string_to_seconds(start_time) + 10
          default_end = EdlParser.translate_time_to_human_readable(default_end)
        end
        end_time = get_user_input("At what point in the video would you like to finish your preview? (like 02:00 for ending at the 2 minute mark)", default_end)
        unless start_time and end_time
          JOptionPane.showMessageDialog(nil, " Please choose start and end", "Failed", JOptionPane::ERROR_MESSAGE)
          return
        end
        Storage['start_time'] = start_time
        Storage['end_time'] = end_time
      end
      dvd_title = descriptors['name'] || dvd_volume_name
      save_to = get_save_to_filename dvd_title
      fulli = MencoderWrapper.calculate_final_filename save_to
      if exit_early_if_fulli_exists
        if File.exist? fulli + ".done"
          return [true, fulli]
        end
        # make it create a dummy response file for us :)
        start_time = "00:00"
        end_time = "00:01"
      end
      
      dvd_title_track = get_title_track(descriptors)
      should_run_mplayer = should_prompt_for_start_and_end_times || exit_early_if_fulli_exists
      require_deletion_entry = true unless watch_unedited
      generate_and_run_bat_file save_to, edit_list_path, descriptors, drive, dvd_title, start_time, end_time, dvd_title_track, should_run_mplayer, require_deletion_entry
      [false, fulli] # false means it's running in a background thread :P
    end

    def get_drive_with_most_space_with_slash
      DriveInfo.get_drive_with_most_space_with_slash
    end
    
    # stubbable :)
    def get_mencoder_commands descriptors, drive, save_to, start_time, end_time, dvd_title_track, require_deletion_entry
      delete_partials = true unless start_time
      MencoderWrapper.get_bat_commands descriptors, drive, save_to, start_time, end_time, dvd_title_track, delete_partials, require_deletion_entry # delete partials...
    end

    def generate_and_run_bat_file save_to, edit_list_path, descriptors, drive, dvd_title, start_time, end_time, dvd_title_track, run_mplayer, require_deletion_entry
      Storage['last_params'] = [save_to, edit_list_path, descriptors, drive, dvd_title, start_time, end_time, dvd_title_track, run_mplayer, require_deletion_entry]
      begin
        commands = get_mencoder_commands descriptors, drive, save_to, start_time, end_time, dvd_title_track, require_deletion_entry
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
      popup = NonBlockingDialog.new(
      "Applying #{File.basename edit_list_path} \n   against #{drive} (#{dvd_title}).\n" +
      "Copying to #{save_to}.\n" +
      "This could take quite awhile, and will prompt you and chime a noise when it is done.\n" +
      "You can close this window and continue working while it runs in the background.\n" +
      "NB that the created file will be playable only with VLC (possibly with smplayer, possibly with\n" +
      "Windows Media Player if you install ffdshow first with mpeg2 video checkbox checked.).",
      "OK")

      # allow our popups to still be serviced while it is running
      @background_thread = Thread.new {
        run_create_commands commands, save_to, run_mplayer
        popup.dispose
      }
      # LODO warn if they will overwrite a file in the end...
    end
    
    attr_accessor :background_thread, :buttons

    def run_create_commands batch_commands, save_to, run_mplayer
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
          if line =~ /@rem /
            success = true # these fail fof some reason?
          else
            puts "\n", 'line failed: ' + line + "\n" + '   see troubleshooting in README.txt file!' unless success
          end
        end
        @progress_bar.set_value(10 + idx/total_size*90)
      }
      @progress_bar.visible=false
      @buttons.each{|b| b.set_enabled true}
      if success
        saved_to = save_to + '.avi'
        if run_mplayer
          system_non_blocking "smplayer #{saved_to}"
        else
          # lodo NonBlockingDialog once it can get to the top instead of being so buried...
          show_file = "explorer /e,/select,\"#{File.expand_path(saved_to).to_filename}\""
          system_blocking show_file # returns immediately
          PlayAudio.play(File.expand_path(File.dirname(__FILE__)) + "/../vendor/music.wav")
          show_blocking_message_dialog "Done--you may now watch file\n #{saved_to}\n in VLC player (or possibly smplayer)"
        end
      else
        show_blocking_message_dialog("Failed--please examine console output and report back!\nAlso consult the troubleshooting section of the README file.", "Failed", JOptionPane::ERROR_MESSAGE)
      end
    end

    # returns e:\, volume, md5sum
    def choose_dvd_drive
      opticals = DriveInfo.get_dvd_drives_as_openstruct
      if @saved_opticals == opticals
        # memoize...kind of :)
        return @_choose_dvd_drive
      end
      show_blocking_message_dialog 'insert a dvd first' unless opticals.find{|d| d.VolumeName }
      names = opticals.map{|d| d.Name + "\\" + " (" +  (d.VolumeName || 'Insert DVD to use') + ")"}

      if opticals.length != 1
        count = 0
        opticals.each{|d| count += 1 if d.VolumeName}
        if count == 1
         # just choose it if there's only one disk in there
         p 'selecting only disk present in the various DVD drives'
         selected_idx = opticals.index{|d| d.VolumeName}
        else
          dialog = GetDisk.new(self, names)
          dialog.setSize 200,125
          dialog.show
          selected_idx = dialog.selected_idx
        end
      else
        selected_idx = 0
        p 'selecting user\'s only disk drive ' + names[0]
      end

      if selected_idx
        disk = opticals[selected_idx]
        prefix = names[selected_idx][0..2]
        puts "calculating disk's unique id..."
        md5sum = DriveInfo.md5sum_disk(prefix)
        @_choose_dvd_drive = [prefix, opticals[selected_idx].VolumeName, md5sum]
        @saved_opticals = opticals
        return @_choose_dvd_drive
      else
        puts 'did not select a drive...hard exiting'
        java.lang.System.exit 1
      end
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
      pack
    end
  end
end

require 'ffi'

module Win
  extend FFI::Library
  ffi_lib 'kernel32'
  ffi_convention :stdcall
  attach_function :get_process_id, :GetProcessId, [ :long ], :uint
end

if $0 == __FILE__
  a = SensibleSwing::MainWindow.new
  a.set_visible true
  puts 'Please use the Sensible Cinema GUI window popup...'
end

# icon attribution: http://www.threes.com/index.php?option=com_content&view=article&id=1800:three-wise-monkeys&catid=82:mythology&Itemid=62