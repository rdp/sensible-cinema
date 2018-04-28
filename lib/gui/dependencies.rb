require 'java'
require 'sane'
require 'open-uri'
require 'fileutils'

module SensibleSwing
  
  class MainWindow < javax.swing.JFrame    
	 
    def force_accept_license_first
      if !(LocalStorage['main_license_accepted'] == VERSION)
        require_blocking_license_accept_dialog 'Sensible Cinema', 'LGPL', 'https://www.gnu.org/licenses/lgpl.html', 'Sensible Cinema license agreement', 
            "Sensible Cinema is distributed under the LGPL (https://www.gnu.org/licenses/lgpl.html).\nBY CLICKING \"accept\" YOU SIGNIFY THAT YOU HAVE READ, UNDERSTOOD AND AGREED TO ABIDE BY THE TERMS OF THIS LICENSE"
        LocalStorage['main_license_accepted'] = VERSION
      end
    end
    
    def force_accept_file_style_license
	program, license_name, license_url_or_full_path_should_also_be_embedded_by_you_in_message, 
      title = 'Confirm Acceptance of License Agreement', message = nil
       if !(LocalStorage['accepted_legal_copys'] == VERSION)
        require_blocking_license_accept_dialog 'Sensible Cinema', 'Legal Page', "https://github.com/rdp/sensible-cinema/wiki/Legality", 
            'Legal Page', 'I acknowledge that I have read, understand, accept the documentation Legal Pages file.'
        LocalStorage['accepted_legal_copys'] = VERSION
      end
    end
   
    def self.download full_url, to_here, english_name = File.basename(to_here)
      if full_url =~ /https/
        require 'openssl'
        eval("OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE")
      end
      puts "downloading #{full_url}..."
      out_frame = JFrame.new("downloading #{english_name}...")
      out_frame.show
      out_frame.setSize(500,15)
      temp_filename = to_here + '.temp'
      writeOut = File.open(temp_filename, "wb")
      content_length = nil
      last_percent = 0
      progress_proc = proc {|p|
        if content_length
          percent = (p.to_f/content_length*100).to_i
          title = "Downloading: At #{percent}% of #{english_name} (#{content_length/1000000}M)"
        else
          title="Downloading: got #{p} bytes of #{english_name}"
        end
        out_frame.title=title
        print '.' if last_percent != percent
        last_percent = percent
      }     
      connection = open(full_url, 'rb', :content_length_proc => proc {|cl| content_length = cl}, :progress_proc => progress_proc)
      contents = connection.read
      connection.close
      writeOut.write contents
      writeOut.close
      out_frame.close
      FileUtils.mv temp_filename, to_here # avoid partial downloads corrupting us
      puts 'success downloading ' + english_name
    end    
    
    def self.download_to_string full_url
     # skip the GUI stuff :)
     # assume don't want cacheing either...
     connection = open(full_url)
     out = connection.read
     connection.close
	   return out
    end

    def download_7zip
      Dir.mkdir('./vendor/cache') unless File.directory? 'vendor/cache' # development may not have it created yet... [?]
      unless File.exist? 'vendor/cache/7za.exe'
        Dir.chdir('vendor/cache') do
          print 'downloading unzipper (7zip--400K) ...'
          MainWindow.download("https://bintray.com/rdp/sensible-cinema/download_file?file_path=7za920.zip", "7za920.zip")
          system_blocking("../unzip.exe -o 7za920.zip") # -o means "overwrite" without prompting
        end
      end
    end
    
    def download_zip_file_and_extract english_name, url, to_this, file_name = nil
      download_7zip
      Dir.chdir('vendor/cache') do
        file_name ||= url.split('/')[-1]
        print "downloading #{english_name} ..."
        MainWindow.download(url, file_name)
        system_blocking("7za e #{file_name} -y -o#{to_this}")
        puts 'done ' + english_name
        # creates vendor/cache/mencoder/mencoder.exe...
      end
    end
    
    def check_for_exe windows_full_loc, unix_name_in_opt_rdp
      # in windows, that exe *at that location* must exist...
      if OS.windows?
        File.exist?(windows_full_loc)
      else
        require 'lib/check_installed_mac_linux.rb'
        if !CheckInstalledMacLinux.check_for_installed(unix_name_in_opt_rdp)
          exit 1 # it'll have already displayed a message...
        else
          true
        end
      end
    end
	
    def check_for_ffmpeg_installed
      ffmpeg_exe_loc = File.expand_path('vendor/cache/ffmpeg/ffmpeg.exe') # I think file based still uses ffmpeg locally...
      if !check_for_exe(ffmpeg_exe_loc, 'ffmpeg')
        require_blocking_license_accept_dialog 'ffmpeg', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: ffmpeg."
        download_zip_file_and_extract "ffmpeg (5MB)", "https://bintray.com/rdp/sensible-cinema/download_file?file_path=ffmpeg-20160525-git-9591ca7-win32-static.7z", "ffmpeg", "ffmpeg-20160525-git-9591ca7-win32-static.7z"
      end
	
	end
	
	def assert_mplayer_up_to_date
	  out = `#{mplayer_local} -fake 2>&1`
	  if out !~ /EDL-0.6/
	    SimpleGuiCreator.show_message "your mplayer may be out of date, need version EDL-0.6, download new mac-dependencies package possibly https://sourceforge.net/projects/mplayer-edl/files/mac-dependencies/ , or ask on mailing list\n. Your version: #{out =~ /(.*MPlayer.*)/; $1}"   
            raise "please update mplayer #{out}"
      end
	end
    
    def check_for_various_dependencies
      if OS.doze?	
        if !check_for_exe(mplayer_local(false), nil)
          require_blocking_license_accept_dialog 'Mplayer-EDL', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: mplayer EDL "
          FileUtils.mkdir_p 'vendor/cache/mplayer_edl'
          MainWindow.download('https://sourceforge.net/projects/mplayer-edl/files/' + File.basename(mplayer_local false), mplayer_local(false))
          config_dir = File.expand_path('~/mplayer')
          FileUtils.mkdir(config_dir) unless File.directory?(config_dir)
          FileUtils.cp('vendor/subfont.ttf', config_dir) # TODO mac ttf?
		end
	  else
	    check_for_exe(nil, 'mplayer') # os x, raises on failure
	  end
	  assert_mplayer_up_to_date
		
	  if OS.doze?
        path = RubyWhich.new.which('smplayer')
        if(path.length == 0)
          # this one has its own installer...
          require_blocking_license_accept_dialog 'SMPlayer', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: smplayer."
          save_to_dir = SimpleGuiCreator.new_existing_dir_chooser_and_go 'pick dir to save smplayer exe installer to:'
          filename = "smplayer-0.6.9-win32.exe"
          save_to_file =  "#{save_to_dir}/#{filename}"
          puts "downloading smplayer.exe [14MB] to #{save_to_file}"
          MainWindow.download "http://smplayer-clean.googlecode.com/files/#{filename}", save_to_file
          show_blocking_message_dialog "Run this file to install it now (click ok to reveal): #{filename}"
          SimpleGuiCreator.show_in_explorer save_to_file
          # system("save_to_file") # unfortunately fails for some reason[?]
          sleep 3
          show_blocking_message_dialog "please hit ok AFTER you have installed SMPlayer has been installed fully..."          
          add_smplayer_paths # load it back onto the PATH now that it's installed so its path exists...
          raise 'smplayer not installed, try restarting!' unless RubyWhich.new.which('smplayer').length > 0
        end
      end
    end
    
    def require_blocking_license_accept_dialog program, license_name, license_url_or_full_path_should_also_be_embedded_by_you_in_message, 
      title = 'Confirm Acceptance of License Agreement', message = nil
	  
      puts 'Please confirm license agreement in open window before proceeding.'
      
      message ||= "Sensible Cinema requires a separately installed program (#{program}), not yet installed.
        You can install this program manually to the vendor/cache subdirectory, or Sensible Cinema can download it for you.
        By clicking accept, below, you are confirming that you have read and agree to be bound by the
        terms of its license (the #{license_name}), located at #{license_url_or_full_path_should_also_be_embedded_by_you_in_message}.  
        Click 'View License' to view it.  If you do not agree to these terms, click 'Cancel'.  You also agree that this is a 
        separate program, with its own distribution, license, ownership and copyright.  
        You agree that you are responsible for the download and use of this program, within sensible cinema or otherwise."
      answer = JOptionPane.show_select_buttons_prompt message, :no => "I have read and Accept the terms of the #{license_name} License Agreement.", :yes => "View #{license_name}"
      assert_confirmed_dialog answer, license_url_or_full_path_should_also_be_embedded_by_you_in_message
      p 'confirmation of sensible cinema related license duly noted of: ' + license_name # LODO require all licenses together :P
    end
    
    def assert_confirmed_dialog returned, license_url_should_also_be_embedded_by_you_in_message
      # :yes is "view license", :no is "accept", :cancel
      if returned == :yes
        if license_url_should_also_be_embedded_by_you_in_message
          SimpleGuiCreator.open_url_to_view_it_non_blocking license_url_should_also_be_embedded_by_you_in_message
          puts "Please restart after reading license agreement, to be able to then accept it."
        else
          puts 'dialog assertion failed'
        end
        System.exit 0
      elsif returned == :cancel
        p 'license not accepted...exiting'
        System.exit 1
      elsif returned == :exited
        p 'license exited early...exiting'
        System.exit 1
      elsif returned == :no
        # ok
      else
        raise 'unknown?'
      end
    end
	
	def set_individual_preferences
          get_set_preference 'mplayer_beginning_buffer', "How much extra \"buffer\" time to add at the beginning of all cuts/mutes in normal mode [for added safety sake]."
          return if in_online_player_startup_mode # don't need the rest...

      if SimpleGuiCreator.show_select_buttons_prompt("Would you like to use this with Zoom Player MAX's scene cuts [3rd party player program, costs $],\n or MPlayer et al [free]", :no => "ZoomPlayer MAX/PowerDVD", :yes => "MPlayer [free]") == :no	  
	    SimpleGuiCreator.show_message "ZoomPlayer support has been added to your release, with the 'create zoomplayer max' button. Ping me and I will add PowerDVD remix support button as well."
        LocalStorage['have_zoom_button'] = true
      else
	    LocalStorage['have_zoom_button'] = false
	  end
	  
      if SimpleGuiCreator.show_select_buttons_prompt("Would you like to enable some obscure options? They are:
 Using keyboard shortcuts to create EDL files on the fly, while watching, with keystrokes,
 Prompting to create euphemized .srt files, for later playback as subtitles, and
 Being able to add your own 'profanity words' to search for, in the subtitles, specific to unique videos?
 (Most users answer no to this).", :yes => 'No', :no => 'Yes') == :no
        LocalStorage['prompt_obscure_options'] = true
      else
	    LocalStorage['prompt_obscure_options'] = false
	  end
	  if SimpleGuiCreator.show_select_buttons_prompt("Would you like to enable upconversion [i.e. make playback prettier, requires more cpu?]") == :yes
	    setup_dvd_upconvert_options
	  else
	    reset_upconversion_options
	  end
	  true
	end
    
    def get_set_preference name, english_name
      old_preference = LocalStorage[name]
      old_class = old_preference.class
	  new_preference = get_user_input("Enter value for #{english_name}", old_preference)
      display_and_raise 'enter something like 0.0' if new_preference.empty?
      if old_class == Float
        new_preference = new_preference.to_f
      elsif old_class == String
        # leave same
      else
        raise 'unknown type?' + old_class.to_s
      end
      LocalStorage[name] = new_preference
    end
  end # MainWindow
end
