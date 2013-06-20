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
require 'ostruct'
require File.expand_path(File.dirname(__FILE__) + '/common')

Dir.chdir '..' # need to run in the main folder, common moves us to spec...
load 'bin/sensible-cinema'
#require_relative 'lib/edl_parser' # to avoid having require_relative collide with autoload <sigh>

module SensibleSwing
  describe MainWindow do
    it "should be able to start up" do
      MainWindow.new.dispose# doesn't crash :)
    end

   it "should have working is_dvd method for mac"

    Test_DVD_ID = 'deadbeef|8b27d001'
    
    it "should die if you file select a poorly formed edl" do
      time_through = 0
      EdlParser.stub!(:single_edit_list_matches_dvd) { |dir, md5|
        'fake filename doesnt matter what we return here because we fake its parsing later anyway'
      }
      
      @subject.stub!(:parse_edl) {
        time_through += 1
        eval("a-----") # force it to throw a Syntax Error first time
      }
      proc { @subject.choose_dvd_or_file_and_edl_for_it}.should raise_exception(SyntaxError)
      @show_blocking_message_dialog_last_arg.should be nil
      time_through.should == 1
    end
    
    def with_clean_edl_dir_as this
      FileUtils.rm_rf 'temp'
      Dir.mkdir 'temp'
      old_edl = EdlParser::EDL_DIR.dup
      EdlParser::EDL_DIR.sub!(/.*/, 'temp')
      begin
        yield
      ensure
        EdlParser::EDL_DIR.sub!(/.*/, old_edl)
      end
    end
    
    it "should not modify path to have mplayer available" do
      ENV['PATH'].should_not include("mplayer")
    end
    
    before do
      File.write('selected_file', '"name" => "a dvd name to satisfy internal assertion", "dvd_title_track" => "2", "mutes" => ["06:10", "06:15"]')
    end
    
    before do
      @subject = MainWindow.new false # false to speedup tests
      # want lots of buttons :)
      @subject.setup_advanced_buttons
      @subject.setup_normal_buttons
      @subject.add_options_that_use_local_files
      FileUtils.touch "selected_file.fulli_unedited.tmp.mpg.done" # a few of them need this...
      FileUtils.touch 'selected_file.avi'
      @subject.stub!(:choose_dvd_drive_or_file) {
        ["mock_dvd_drive", "Volume", Test_DVD_ID] # happiest baby on the block
      }
      @subject.stub!(:get_mencoder_commands) { |*args|
        args[-5].should == 'selected_file'
        @get_mencoder_commands_args = args
        'fake get_mencoder_commands'
      }
      @subject.stub!(:new_existing_file_selector_and_select_file) {
        'selected_file'
      }
      @subject.stub!(:new_nonexisting_filechooser_and_go) {
        'selected_file' # TODO do we need FakefileChooser anymore?
      }
      @subject.stub!(:get_drive_with_most_space_with_slash) {
        "e:\\"
      }
      @subject.stub!(:show_blocking_message_dialog) { |*args|
        @show_blocking_message_dialog_last_arg = args[0]
      }
      
      @subject.stub!(:get_user_input) {'01:00'}
      @subject.stub!(:system_blocking) { |*command|
        @system_blocking_command = command[0]
      }

      @subject.stub!(:system_non_blocking) { |command|
        @system_non_blocking_command = command
        Thread.new {} # fake out the return...
      }
      @subject.stub!(:open_file_to_edit_it) {}
      
      PlayAudio.stub!(:play) {
        # don't play anything, by default :)
      }
      
      @subject.stub!(:show_in_explorer) {|filename|}
      unless $VERBOSE
        # less chatty...
        @subject.stub!(:print) {}
        @subject.stub!(:p) {}
        @subject.stub!(:puts) {}
        EdlParser.stub!(:p) {}
      end
      
      @subject.stub(:show_non_blocking_message_dialog) {
         # don't display the popup message...
        fake_window = OpenStruct.new
        fake_window.dispose = :ok
        fake_window
      }
    end
    
    before do
      EdlParser::EDL_DIR.gsub!(/^.*$/, 'spec/files/edls')
    end
    
    after do
      # too dangerous...if it ever joins on a swing thread lights out!
      #Thread.join_all_others
      FileUtils.rm_rf EdlParser::EDL_DIR
      Dir.mkdir EdlParser::EDL_DIR
    end

    class FakeFileChooser
      def set_title x; end
      def set_file y; end
      def set_current_directory x; end
      def get_current_directory ; 'a great dir!'; end
      def go
        'selected_file'
      end
    end
    
    # name like :@rerun_previous
    def click_button(name)
      button = @subject.instance_variable_get(name)
      raise 'button not found: ' + name.to_s unless button
      button.simulate_click
    end
    
    it "should be able to run system" do
      @subject.system_non_blocking "ls"
    end

    it "should have a good default title of 1" do
     @subject.get_title_track({}).should == "1"
     descriptors = {"dvd_title_track" => "3"}
     @subject.get_title_track(descriptors).should == "3"
    end
    
    def assert_played_mplayer # used?
      Thread.join_all_others
      if OS.doze?
        @system_blocking_command.should =~ /smplayer/
      else
        @system_blocking_command.should =~ /mplayer/
      end
    end

    def run_preview_section_button_successfully
      click_button(:@preview_section)
      join_background_thread
      @get_mencoder_commands_args[-2].should == "2"
      @get_mencoder_commands_args[-3].should == "01:00"
      assert_played_mplayer
    end

    it "should prompt for start and end times" do
      run_preview_section_button_successfully
    end
    
    temp_dir = Dir.tmpdir
    
    def join_background_thread
      @subject.background_thread.join # force it to have been started at least
      Thread.join_all_others # just in case...
    end
    
    it "should warn if you give it an mkv file, just in case" do
      @subject.stub!(:run_smplayer_blocking) {} # avoid check for file existence
      @subject.unstub!(:get_mencoder_commands) # this time through, let it really check for existence of edits...
      @subject.stub!(:get_user_input).and_return('06:00', '07:00')
      click_button(:@preview_section)
      @show_blocking_message_dialog_last_arg.should =~ /is not a/
      join_background_thread
    end
    
    it "should not warn if a ts file, and has appropriate entries within timeframe" do
      @subject.stub!(:get_user_input).and_return('06:00', '07:00')
      @subject.stub!(:new_existing_file_selector_and_select_file).and_return('selected_file', 'selected_file.mpg')
      click_button(:@preview_section)
      
      @show_blocking_message_dialog_last_arg.should =~ /preview just a portion/
      join_background_thread # weird...rspec you should do my after blocks before you'n... LODO
    end
    
    it "should create a new file based on stats of current disc" do
      out = EdlParser::EDL_DIR + "/sweetest_disc_ever.txt"
      FileUtils.mkdir_p File.dirname(out)
      File.exist?( out ).should be_false
      @subject.stub!(:get_user_input) {'sweetest disc ever'}
      @subject.instance_variable_get(:@create_new_edl_for_current_dvd).simulate_click
      begin
        File.exist?( out ).should be_true
        content = File.read(out)
        content.should_not include("\"title\"")
        content.should include("disk_unique_id")
        content.should include("dvd_title_track")
        content.should include("mplayer_dvd_splits")
      ensure
        FileUtils.rm_rf out
      end
    end
    
    it "should display unique disc in an input box" do
      click_button(:@display_dvd_info).should =~ /deadbeef/
    end
    
    it "should create an edl and pass it through to mplayer" do
      smplayer_opts = nil
      @subject.stub(:set_smplayer_opts) { |to_this, show_subs|
        smplayer_opts = to_this
      }
      click_button(:@mplayer_edl).join
      smplayer_opts.should match(/-edl /)
      @system_blocking_command.should match(/mock_dvd_drive/) # 
      @system_blocking_command.should_not =~ /dvdnav/ # file based, so no dvdvnav
      @system_blocking_command.should_not =~ /-nocache/ # file based, so no -nocache
    end
    
    it "should handle dvd drive -> dvdnav" do
      for drive in ['d:', 'e:', 'f:', 'g:']
        if File.exist?(drive + '/VIDEO_TS')
          @subject.run_smplayer_blocking drive, nil, '', true, true, true
          @system_blocking_command.should =~ /dvdnav/
          @system_blocking_command.should =~ /-dvd-device/
        end
      end
    end
    
    it 'should handle a/b/VIDEO_TS/yo.vob' do
      FileUtils.mkdir_p f = 'a/b/VIDEO_TS/yo.vob'
      @subject.run_smplayer_blocking f, 3, '', true, false, true
      @system_blocking_command.should =~ /dvdnav:\/\/3/
      @system_blocking_command.should =~ /VIDEO_TS\/\.\./
      @system_blocking_command.should =~ / -alang/ # preceding space :)
      
      # exercise the yes subtitle options...
      @subject.run_smplayer_blocking f, 3, '', true, true, true
      @system_blocking_command.should_not =~ /-nosub/
      
    end
      
    it "should play edl with extra time for the mutes because of the EDL aspect" do
      click_button(:@mplayer_edl).join
      wrote = File.read(MainWindow::EdlTempFile)
      wrote.should include("369.0 375.0 1") # right numbers, except first -= 1
    end
    
    def should_allow_for_changing_file corrupt_the_file = false
       with_clean_edl_dir_as 'temp' do
        File.binwrite('temp/a.txt', "\"disk_unique_id\" => \"abcdef1234\"")
        @subject.stub!(:choose_dvd_drive_or_file) {
          FileUtils.touch 'mock_dvd_drive'
          ["mock_dvd_drive", "Volume", "abcdef1234"]
        }
        @subject.choose_dvd_or_file_and_edl_for_it[4]['mutes'].should == []
        new_file_contents = '"disk_unique_id" => "abcdef1234","mutes"=>["0:33", "0:34"]'
        new_file_contents = '"a syntax error' if corrupt_the_file
        File.binwrite('temp/a.txt', new_file_contents)
        # file has been modified!
        @subject.choose_dvd_or_file_and_edl_for_it[4]['mutes'].should_not == []
      end
    end
    
    it "should allow for file to change contents while editing it" do
      should_allow_for_changing_file
    end
    
    it "should prompt you if you re-choose, and your file now has a failure in it" do
      @subject.stub(:show_blocking_message_dialog) {
        @got_here = true
        @subject.stub(:parse_edl) { 'pass the second time through' }
      }
      should_allow_for_changing_file true
      @got_here.should == true
    end
    
    describe 'with unstubbed choose_dvd_drive_or_file' do
      before do
        DriveInfo.stub!(:get_dvd_drives_as_openstruct) {
          a = OpenStruct.new
          a.VolumeName = 'a dvd name'
          a.Name = 'a path location'
          [a] 
        }
        @subject.unstub!(:choose_dvd_drive_or_file)
      end

      def yo select_a_dvd
        count = 0
        DriveInfo.stub!(:md5sum_disk) {
          count += 1
          Test_DVD_ID
        }
        if !select_a_dvd
          DriveInfo.stub!(:get_dvd_drives_as_openstruct) { [] } # no DVD disks inserted...        
        end
        @subject.stub(:get_disk_chooser_window) {|names|
          a = OpenStruct.new
          def a.setSize x,y; end
          a.stub(:selected_idx) { 0 } # first entry is either DVD name *or* file, and is apparently "0" weird weird weird
          # ruby bug [?] always return nil
          # def a.selected_idx; p 'returning', select_this_idx; select_this_idx; end
          a
        }
        @subject.stub(:new_nonexisting_filechooser_and_go) {|a, b|
           'selected_filename'
        }
        @subject.stub(:new_existing_file_selector_and_select_file) {
          'selected_edl'
        }
        FileUtils.touch 'selected_edl' # blank file is ok :P
        @subject.choose_dvd_or_file_and_edl_for_it
        @subject.choose_dvd_or_file_and_edl_for_it
        count
      end

      it "should only prompt for disk selection once" do
        yo( true ).should == 1 # choose the 'a dvd name' DVD
      end

      it "should only prompt for file selection once" do
        prompted = false
        yo( false ).should == 0 # choose a file, so never dvdid any dvd...
      end
  
      it "should prompt you if you need to insert a dvd" do
        DriveInfo.stub!(:get_dvd_drives_as_openstruct) {
          a = OpenStruct.new
          #a.VolumeName = 'a dvd name' # we "don't have a disk in" for this test...
          a.Name = 'a path location'
          [a]
        }
        proc {@subject.choose_dvd_drive_or_file true}.should raise_error(/no dvd found/)
        @show_blocking_message_dialog_last_arg.should_not be nil
      end
    end
    
    it "should show additional buttons in create mode" do
      MainWindow.new(false).setup_default_buttons.buttons.length.should be > 3
      MainWindow.new(false).setup_default_buttons.buttons.length.should be < 10
      old_length = MainWindow.new(false).setup_default_buttons.buttons.length
      ARGV << "--create-mode"
      MainWindow.new(false).setup_default_buttons.buttons.length.should be > (old_length + 5)
      ARGV.pop # post-test cleanup--why not :)
    end

    it "should show upconvert buttons" do
      ARGV << "--upconvert-mode"
      MainWindow.new(false).setup_default_buttons.buttons.length.should be > 3
      ARGV.pop 
    end 
    
  it "should be able to parse an srt for ya" do
     @subject.stub!(:new_existing_file_selector_and_select_file) {
       'spec/dragon.srt'
     }
     file = SensibleSwing::MainWindow::EdlTempFile
     FileUtils.rm_rf file
     click_button(:@parse_srt)
     assert File.read(file).contain? "deitys"
  end
  
  it "should have a created play unedited smplayer button" do
    click_button(:@play_smplayer)
  end
  
  it "should create an sxs file" do
    FileUtils.rm_rf 'yo.edl' # nothing up my sleeve.
    @subject.stub(:new_existing_file_selector_and_select_file).and_return("yo.mpg", "selected_file")
    click_button(:@create_dot_edl)
    assert File.exist? 'yo.edl'
  end
  
  it "should be able to upconvert at all" do
    MainWindow.any_instance.stub(:display_current_upconvert_setting_and_close_window) {} # TRY it out
    @subject = MainWindow.new(false)
    MainWindow::LocalStorage['screen_multiples'] = 2.0 # default so it won't fail us...
    @subject.add_change_upconvert_buttons
    @subject.stub(:show_mplayer_instructions_once) {}
    click_button(:@medium_dvd)
    storage = MainWindow::LocalStorage
    key = MainWindow::UpConvertKey
    storage[key].should =~ /hqdn3d/
    click_button(:@none)
    storage[key].should be_nil
    click_button(:@medium_dvd)
    
    # now it should use them on mplayer
    got = nil
    @subject.stub(:system_blocking) { |c|
      got = c
    }
    @subject.run_smplayer_blocking 'selected_file.avi', nil, "", true, true, false
    assert got =~ /hqdn3d/
    
    # and on smplayer
    MainWindow::SMPlayerIniFile.gsub!(/^.*$/, File.expand_path('./smplayer_ini_file')) # don't overwrite the real one...
    @subject.run_smplayer_blocking 'selected_file.avi', nil, "", false, true, false
    assert got =~ /mplayer/
    assert File.read(MainWindow::SMPlayerIniFile) =~ /hqdn3d/
  end
  
  it "should be able to play upconverted stuff" do
    @subject.add_play_upconvert_buttons
    click_button(:@watch_file_upconvert)
    assert_played_mplayer
    click_button(:@watch_dvd_upconvert)
    assert_played_mplayer
  end
  
 end # describe MainWindow
  
end
