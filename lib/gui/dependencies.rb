require 'java'

require 'sane'

module SensibleSwing
  
  class MainWindow < javax.swing.JFrame    
	 
    def force_accept_license_first
      if !(LocalStorage['main_license_accepted'] == VERSION)
        require_blocking_license_accept_dialog 'Sensible Cinema', 'gplv3', 'http://www.gnu.org/licenses/gpl.html', 'Sensible Cinema license agreement', 
            "Sensible Cinema is distributed under the gplv3 (http://www.gnu.org/licenses/gpl.html).\nBY CLICKING \"accept\" YOU SIGNIFY THAT YOU HAVE READ, UNDERSTOOD AND AGREED TO ABIDE BY THE TERMS OF THIS AGREEMENT"
        LocalStorage['main_license_accepted'] = VERSION
      end
    end
    
    def force_accept_file_style_license
       if !(LocalStorage['accepted_legal_copys'] == VERSION)
        require_blocking_license_accept_dialog 'Sensible Cinema', 'is_it_legal_to_copy_dvds.txt file', File.expand_path(File.dirname(__FILE__) + "/../../documentation/is_it_legal_to_copy_dvds.txt"), 
            'is_it_legal_to_copy_dvds.txt file', 'I acknowledge that I have read, understand, accept the documentation/is_it_legal_to_copy_dvds.txt file.'
        LocalStorage['accepted_legal_copys'] = VERSION
      end
    end
   
    def self.download full_url, to_here, english_name = File.basename(to_here)
	  return if File.exist? to_here # already downloaded it...
      require 'open-uri'
      require 'fileutils'
      if full_url =~ /https/
        require 'openssl'
        eval("OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE")
      end
      out_frame = JFrame.new("downloading #{english_name}...")
      out_frame.show
      out_frame.setSize(500,15)
      print 'downloading ' + english_name
      temp_filename = to_here + '.temp'
      writeOut = open(temp_filename, "wb")
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
      url = open(full_url, 'rb', :content_length_proc => proc {|cl| content_length = cl}, :progress_proc => progress_proc)
      writeOut.write(url.read)
      url.close
      writeOut.close
      out_frame.close
      FileUtils.mv temp_filename, to_here # avoid partial downloads corrupting uss
      puts 'done downloading ' + english_name
    end    
    
    def self.download_to_string full_url
       require 'tempfile'
       to = Tempfile.new 'abc'
       download(full_url, to.path)
       out = File.binread(to.path)
       to.delete
       out
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
	
	def check_for_ffmpeg_installed
      ffmpeg_exe_loc = File.expand_path('vendor/cache/ffmpeg/ffmpeg.exe') # I think file basd normal needs ffmpeg
      if !check_for_exe(ffmpeg_exe_loc, 'ffmpeg')
        require_blocking_license_accept_dialog 'ffmpeg', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: ffmpeg."
        download_zip_file_and_extract "ffmpeg (5MB)", "http://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-git-335bbe4-win32-static.7z", "ffmpeg"
      end
	
	end
    
    def check_for_various_dependencies            
      if OS.doze? && !check_for_exe('vendor/cache/mplayer_edl/mplayer.exe', nil)
        require_blocking_license_accept_dialog 'Mplayer-EDL', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: mplayer EDL "
        FileUtils.mkdir_p 'vendor/cache/mplayer_edl'
        puts 'downloading mplayer edl [12 MB]'
        MainWindow.download('http://sourceforge.net/projects/mplayer-edl/files/0.5/mplayer.exe', 'vendor/cache/mplayer_edl/mplayer.exe')
        config_dir = File.expand_path('~/mplayer')
        FileUtils.mkdir(config_dir) unless File.directory?(config_dir)
        FileUtils.cp('vendor/subfont.ttf', config_dir) # TODO mac
      end

      # runtime dependencies, at least as of today...
      if OS.mac?
        check_for_exe("mplayer", "mplayer") # mencoder and mplayer are separate for mac... [this checks for mac's mplayerx, too]
      else      
        path = RubyWhich.new.which('smplayer')
        if(path.length == 0)
          # this one has its own installer...
          require_blocking_license_accept_dialog 'Smplayer', 'gplv2', 'http://www.gnu.org/licenses/gpl-2.0.html', "Appears that you need to install a dependency: smplayer."
          save_to_dir = SimpleGuiCreator.new_existing_dir_chooser_and_go 'pick dir to save smplayer exe installer to:'
          filename = "smplayer-0.6.9-win32.exe"
          save_to_file =  "#{save_to_dir}/#{filename}"
          puts "downloading smplayer.exe [14MB] to #{save_to_file}"
          MainWindow.download "http://sourceforge.net/projects/smplayer/files/SMPlayer/0.6.9/#{filename}", save_to_file
          #system(save_to_file) # unfortunately fails...
          show_blocking_message_dialog "Run this file to install it now (click ok to reveal): #{filename}"
          SimpleGuiCreator.show_in_explorer save_to_file
          sleep 3
          show_blocking_message_dialog "please run the file #{filename} in the other window, and then hit ok AFTER you have installed smplayer fully..."          
          add_smplayer_paths # load it back onto the PATH now that it's installed so its path exists...
          raise 'smplayer not installed' unless RubyWhich.new.which('smplayer').length > 0
        end
      end
    end
    
    def assert_ownership_dialog 
      force_accept_file_style_license
      message = "Do you certify you own the DVD this came of and have it in your possession, if necessary?"
      title = "Verify ownership"
      returned = JOptionPane.show_select_buttons_prompt(message, {:yes => "no", :no => "yes"})
      assert_confirmed_dialog returned, nil
    end
  
    def require_blocking_license_accept_dialog program, license_name, license_url_should_also_be_embedded_by_you_in_message, 
      title = 'Confirm Acceptance of License Agreement', message = nil
      puts 'Please confirm license agreement in open window before proceeding.'
      
      message ||= "Sensible Cinema requires a separately installed program (#{program}), not yet installed.
        You can install this program manually to the vendor/cache subdirectory, or Sensible Cinema can download it for you.
        By clicking accept, below, you are confirming that you have read and agree to be bound by the
        terms of its license (the #{license_name}), located at #{license_url_should_also_be_embedded_by_you_in_message}.  
        Click 'View License' to view it.  If you do not agree to these terms, click 'Cancel'.  You also agree that this is a 
        separate program, with its own distribution, license, ownership and copyright.  
        You agree that you are responsible for the download and use of this program, within sensible cinema or otherwise."
      answer = JOptionPane.show_select_buttons_prompt message, :no => "I have read and Accept the terms of the #{license_name} License Agreement.", :yes => "View #{license_name}"
      assert_confirmed_dialog answer, license_url_should_also_be_embedded_by_you_in_message
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
      if JOptionPane.show_select_buttons_prompt("Would you like to use this with Zoom Player MAX's scene cuts [3rd party player program, costs $], or MPlayer et al [free]", :no => "ZoomPlayer MAX", :yes => "MPlayer/VLC/DVD-Navigator [all free]") == :no
        LocalStorage['have_zoom_button'] = true
      else
	    LocalStorage['have_zoom_button'] = false
	  end
	  # TODO break these out into create mode prefs versus human [?]
      if JOptionPane.show_select_buttons_prompt("Would you like to enable some obscure options, like
 Using keyboard shortcuts to create EDL files on the fly, or 
 Prompting to create euphemized .srt files, or
 Being able to add your own 'profanity words' specific to different videos?
 (Most users answer no to this).", :yes => 'No', :no => 'Yes') == :no
        LocalStorage['prompt_obscure_options'] = true
      else
	    LocalStorage['prompt_obscure_options'] = false
	  end
	  if JOptionPane.show_select_buttons_prompt("Would you like to enable upconversion [i.e. make playback prettier, requires more cpu?]") == :yes
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
