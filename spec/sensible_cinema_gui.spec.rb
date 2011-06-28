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

module SensibleSwing
  describe MainWindow do

    it "should be able to start up" do
      MainWindow.new.dispose# doesn't crash :)
    end

    Test_DVD_ID = 'deadbeef|8b27d001'
    
    it "should auto-select a EDL if it matches a DVD's title" do
      MainWindow.new.single_edit_list_matches_dvd(Test_DVD_ID).should_not be nil
    end

    it "should not auto-select if you pass it nil" do
      MainWindow.new.single_edit_list_matches_dvd(nil).should be nil
    end
    
    it "should not die if you choose a poorly formed edl (should warn)" do
      time_through = 0
      @subject.stub!(:single_edit_list_matches_dvd) {
        'fake filename doesnt matter because we fake its being parsed'
      }
      
      @subject.stub!(:parse_edl) {
        if time_through == 0
          time_through += 1
          eval("a-----") # force it to throw a Syntax Error first time
        else
          "stuff"
        end
      }
      @subject.choose_dvd_and_edl_for_it
      @show_blocking_message_dialog_last_arg.should_not be nil
    end
    
    it "should warn if you don't have enough disk space" do
      @subject.get_freespace('.').should be > 0
      @subject.get_freespace("c:\\nonexistent").should be > 0
      @subject.stub!(:get_freespace) {
        0
      }
      @subject.get_save_to_filename 'dvd_title'
      @show_blocking_message_dialog_last_arg.should =~ /may not be enough/
    end
    
    it "should not warn if you have enough free disk space" do
      @subject.stub!(:get_freespace) {
        16_000_000_000
      }
      @subject.get_save_to_filename 'dvd_title'
      @show_blocking_message_dialog_last_arg.should be nil
    end
    
    it "should not select a file if poorly formed" do
      @subject.stub!(:parse_edl) {
        eval("a----")
      }
      @subject.single_edit_list_matches_dvd('fake md5') # doesn't die
    end
    
    def with_clean_edl_dir_as this
      FileUtils.rm_rf 'temp'
      Dir.mkdir 'temp'
      old_edl = MainWindow::EDL_DIR.dup
      MainWindow::EDL_DIR.sub!(/.*/, 'temp')
      begin
        yield
      ensure
        MainWindow::EDL_DIR.sub!(/.*/, old_edl)
      end
    end
    
    it "should prompt if two EDL's match a DVD title" do
      MainWindow.new.single_edit_list_matches_dvd("BOBS_BIG_PLAN").should be nil
      with_clean_edl_dir_as 'temp' do
        MainWindow.new.single_edit_list_matches_dvd("BOBS_BIG_PLAN").should be nil
        Dir.chdir 'temp' do
          File.binwrite('a.txt', "\"disk_unique_id\" => \"abcdef1234\"")
          File.binwrite('b.txt', "\"disk_unique_id\" => \"abcdef1234\"")
        end
        MainWindow.new.single_edit_list_matches_dvd("abcdef1234").should be nil
      end
    end

    it "should modify path to have mencoder available" do
      ENV['PATH'].should include("mencoder")
    end
    
    it "should not modify path to have mplayer available" do
      ENV['PATH'].should_not include("mplayer")
    end
    
    before do
      @subject = MainWindow.new
      @subject.stub!(:choose_dvd_drive) {
        ["mock_dvd_drive", "Volume", Test_DVD_ID] # happiest baby on the block
      }
      @subject.stub!(:get_mencoder_commands) { |*args|
        args[-5].should match(/abc/)
        @get_mencoder_commands_args = args
        'fake get_mencoder_commands'
      }
      @subject.stub!(:new_filechooser) {
        FakeFileChooser.new
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
      
      @subject.stub!(:get_freespace) {
        # during testing, we *always* have enough free space :)
        16_000_000_000
      }
      # less chatty...
      @subject.stub!(:p) {}
      @subject.stub!(:puts) {}

    end
    
    after do
      @subject.background_thread.join if @subject.background_thread
    end

    class FakeFileChooser
      def set_title x; end
      def set_file y; end
      def set_current_directory x; end
      def get_current_directory ; 'a great dir!'; end
      def go
        'abc'
      end
    end
    
    # name like :@rerun_previous
    def click_button(name)
      @subject.instance_variable_get(name).simulate_click
    end
    
    it "should be able to run system" do
      @subject.system_non_blocking "ls"
    end

    it "should be able to do a normal copy to hard drive, edited" do
      @subject.do_copy_dvd_to_hard_drive(false).should == [false, "abc.fulli_unedited.tmp.mpg"]
      File.exist?('test_file_to_see_if_we_have_permission_to_write_to_this_folder').should be false
    end
    
    it "should prompt twice for filenames--once for the 'to' filename, once for the 'from' filename" do
      count = 0
      @subject.stub!(:new_filechooser) {
        count += 1
        FakeFileChooser.new
      }
      @subject.do_copy_dvd_to_hard_drive(false).should == [false, "abc.fulli_unedited.tmp.mpg"]
      count.should == 2
    end
    
    it "should have a good default title of 1" do
     @subject.get_title_track({}).should == "1"
     descriptors = {"dvd_title_track" => "3"}
     @subject.get_title_track(descriptors).should == "3"
    end
    
    it "should call through to explorer for the full thing" do
      PlayAudio.stub!(:play) {
        @played = true
      }
      @subject.do_copy_dvd_to_hard_drive(false)
      @subject.background_thread.join
      @get_mencoder_commands_args[-4].should == nil
      @system_blocking_command.should match /explorer/
      @system_blocking_command.should_not match /fulli/
      @played.should == true
    end
    
    it "should be able to return the fulli name if it already exists" do
      FileUtils.touch "abc.fulli_unedited.tmp.mpg.done"
      @subject.do_copy_dvd_to_hard_drive(false,true).should == [true, "abc.fulli_unedited.tmp.mpg"]
      FileUtils.rm "abc.fulli_unedited.tmp.mpg.done"
    end
    
    it "should call explorer eventually, if it has to create the fulli file" do
     @subject.do_copy_dvd_to_hard_drive(true).should == [false, "abc.fulli_unedited.tmp.mpg"]
     join_background_thread
     @get_mencoder_commands_args[-2].should == "2"
     @get_mencoder_commands_args[-3].should == "01:00"
     @system_non_blocking_command.should match /smplayer/
     @system_non_blocking_command.should_not match /fulli/
    end

    def run_preview_section_button_successfully
      click_button(:@preview_section)
      join_background_thread
      @get_mencoder_commands_args[-2].should == "2"
      @get_mencoder_commands_args[-3].should == "01:00"
      @system_non_blocking_command.should match /smplayer/
    end

    it "should prompt for start and end times" do
      run_preview_section_button_successfully
    end
    
    temp_dir = Dir.tmpdir
    
    def join_background_thread
      @subject.background_thread.join # must be running...
    end
    
    it "should be able to preview unedited" do
      @subject.stub!(:get_user_input).and_return('06:00', '07:00')
      @subject.unstub!(:get_mencoder_commands)
      click_button(:@preview_section_unedited)
      join_background_thread # scary timing spec
      temp_file = temp_dir + '/vlc.temp.bat'
      File.read(temp_file).should include("59.99")
    end
    
    it "should call something for fast preview" do
      click_button(:@fast_preview).join
      join_background_thread
      #XXXX @system_blocking_command.should =~ /ffmpeg.*ntsc-dvd/ # I think this is a timing thing...
      @system_blocking_command.should =~ /smplayer/
      @system_blocking_command.should_not =~ /mplayer.*fast/ # the old way
    end
    
    it "should be able to rerun the latest start and end times with the rerun button" do
      run_preview_section_button_successfully
      old_args = @get_mencoder_commands_args
      old_args.should_not == nil
      @get_mencoder_commands_args = nil
      click_button(:@rerun_preview).join
      @get_mencoder_commands_args.should == old_args
      @system_non_blocking_command.should match(/smplayer/)
    end
    
    it "should not die if you pass it the same start and end time frames--graceful acceptance" do
      @subject.stub!(:get_mencoder_commands) {
        raise MencoderWrapper::TimingError
      }
      click_button(:@rerun_preview)
      @show_blocking_message_dialog_last_arg.should =~ /you chose a time frame/
    end
    
    it "should not die if you pass it the same start and end time frames--graceful acceptance" do
      @subject.stub!(:get_mencoder_commands) {
        raise Errno::EACCES
      }
      click_button(:@rerun_preview) # lodo rspec error: wrong backtrace if no => e!
      @show_blocking_message_dialog_last_arg.should =~ /a file/
    end

    it "should warn if you watch an edited time frame with no edits in it" do
      @subject.unstub!(:get_mencoder_commands) # this time through, let it check for existence of edits...
      click_button(:@preview_section)
      @show_blocking_message_dialog_last_arg.should =~ /unable to/
      @subject.stub!(:get_user_input).and_return('06:00', '07:00')
      click_button(:@preview_section)
      join_background_thread
      @system_blocking_command.should == "echo wrote (probably successfully) to abc.avi"
    end
    
    it "if the .done files exists, do_copy... should call smplayer ja" do
      FileUtils.touch "abc.fulli_unedited.tmp.mpg.done"
      @subject.do_copy_dvd_to_hard_drive(false, true, true).should == [true, "abc.fulli_unedited.tmp.mpg"]
    end
    
    it "should create a new file for ya" do
      out = MainWindow::EDL_DIR + "/sweetest_disc_ever.txt"
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
      @subject.instance_variable_get(:@display_unique).simulate_click.should == "01:00"
    end
    
    it "should create an edl and pass it through to mplayer" do
      click_button(:@mplayer_edl).join
      @system_blocking_command.should match(/mplayer.*-edl/)
      @system_blocking_command.should match(/-dvd-device /)
    end
    
    it "should play edl with extra time for the mutes because of the EDL aspect" do
      click_button(:@mplayer_edl).join
      wrote = File.read(MainWindow::EdlTempFile)
      # normally "378.0 379.1 1"
      p wrote
      wrote.should include("377.5 379.1 1")
    end
    
    def should_allow_for_changing_file corrupt_the_file = false
       with_clean_edl_dir_as 'temp' do
        File.binwrite('temp/a.txt', "\"disk_unique_id\" => \"abcdef1234\"")
        @subject.stub!(:choose_dvd_drive) {
          ["mock_dvd_drive", "Volume", "abcdef1234"]
        }
        @subject.choose_dvd_and_edl_for_it[4]['mutes'].should == []
        new_file_contents = '"disk_unique_id" => "abcdef1234","mutes"=>["0:33", "0:34"]'
        new_file_contents = '"a syntax error' if corrupt_the_file
        File.binwrite('temp/a.txt', new_file_contents)
        # file has been modified!
        @subject.choose_dvd_and_edl_for_it[4]['mutes'].should_not == []
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
    
    it "should only prompt for save to filename once" do
      count = 0
      @subject.stub!(:new_filechooser) {
        count += 1
        FakeFileChooser.new
      }
      3.times { @subject.do_copy_dvd_to_hard_drive(false) }
      count.should == 2 # else would have been 6...
    end
    
    describe 'with unstubbed choose_dvd_drive' do
      before do
        DriveInfo.stub!(:get_dvd_drives_as_openstruct) {
          a = OpenStruct.new
          a.VolumeName = 'a dvd name'
          a.Name = 'a path location'
          [a] 
        }
        @subject.unstub!(:choose_dvd_drive)
      end
      
      it "should only prompt for drive once" do
        count = 0
        DriveInfo.stub!(:md5sum_disk) {
          count += 1
          Test_DVD_ID
        }
        @subject.choose_dvd_and_edl_for_it
        @subject.choose_dvd_and_edl_for_it
        count.should == 1
      end
  
      it "should prompt you if you need to insert a dvd" do
        DriveInfo.stub!(:get_dvd_drives_as_openstruct) {
          a = OpenStruct.new
          #a.VolumeName = 'a dvd name' # we "don't have one" for this test...
          a.Name = 'a path location'
          [a] 
        }
        proc {@subject.choose_dvd_drive}.should raise_error(SystemExit)
        @show_blocking_message_dialog_last_arg.should_not be nil
      end
    end
    
    it "should not show the normal buttons in create mode" do
      MainWindow.new.buttons.length.should == 4 # exit button plus two normal buttons
      ARGV << "--create-mode"
      MainWindow.new.buttons.length.should == 16
      ARGV.pop # test cleanup--why not :)
    end
    
    it "should read splits from the file" do
      splits1 = nil
      MplayerEdl.stub(:convert_to_edl) do |d,s,s,splits|
        splits1 = splits
      end
      @subject.do_mplayer_edl nil, 0, 0
      splits1.should == []
    end
    
    it "should warn if there are no DVD splits and you try to use EDL" do
      with_clean_edl_dir_as 'temp' do
        File.binwrite('temp/a.txt', "\"disk_unique_id\" => \"abcdef1234\"")
        @subject.stub!(:choose_dvd_drive) {
           ["mock_dvd_drive", "mockVolume", "abcdef1234"]
        }
        @subject.do_mplayer_edl(nil, 0, 0)
        @show_blocking_message_dialog_last_arg.should =~ /does not contain mplayer replay information \[mplayer_dvd_splits\]/
      end
   end
  
   it "should be able to parse an srt for ya" do
     @subject.stub!(:new_filechooser) {
       fc = FakeFileChooser.new
       fc.stub!(:go) {
         'spec/dragon.srt'
       }
       fc
     }
     file = SensibleSwing::MainWindow::EdlTempFile
     FileUtils.rm_rf file
     click_button(:@parse_srt)
     assert File.read(file).contain? "deitys"
   end
  
  end # describe MainWindow
  
end
