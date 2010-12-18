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
require File.expand_path(File.dirname(__FILE__) + '/common')
load '../bin/sensible-cinema'

module SensibleSwing
  describe MainWindow do

    it "should be able to start up" do
      MainWindow.new.dispose# shouldn't crash :)
    end

    it "should auto-select a EDL if it matches a DVD's title" do
      MainWindow.new.single_edit_list_matches_dvd("19d121ae8dc40cdd70b57ab7e8c74f76").should_not be nil
    end

    it "should not auto-select if you pass it nil" do
      MainWindow.new.single_edit_list_matches_dvd(nil).should be nil
    end
    
    it "should not die if you choose a poorly formed edl" do
      time_through = 0
      @subject.stub!(:single_edit_list_matches_dvd) {
        'fake filename doesnt even matter because we fake the parsing of it later'
      }
      
      @subject.stub!(:parse_edl) {
        if time_through == 0
          time_through += 1
          eval("a-----") # throws Syntax Error first time
        else
          "stuff"
        end
      }
      @subject.choose_dvd_and_edl_for_it
      @show_blocking_message_dialog_last_args.should_not be nil
    end
    
    it "should not select a file if poorly formed" do
      @subject.stub!(:parse_edl) {
        eval("a----")
      }
      @subject.single_edit_list_matches_dvd 'fake md5'
    end
    
    it "should prompt if two EDL's match a DVD title" do
      old_edl = MainWindow::EDL_DIR
      begin
        MainWindow.const_set(:EDL_DIR, 'temp')
        FileUtils.rm_rf 'temp'
        Dir.mkdir 'temp'
        MainWindow.new.single_edit_list_matches_dvd("BOBS_BIG_PLAN").should be nil
        Dir.chdir 'temp' do
          File.binwrite('a.txt', "\"disk_unique_id\" => \"abcdef1234\"")
          File.binwrite('b.txt', "\"disk_unique_id\" => \"abcdef1234\"")
        end
        MainWindow.new.single_edit_list_matches_dvd("abcdef1234").should be nil
      ensure
      MainWindow.const_set(:EDL_DIR, old_edl)
      end
    end

    it "should modify path to have mencder available, and ffmpeg, and download them on the fly" do
      ENV['PATH'].should include("mencoder")
    end
    
    it "should not modify path to have mplayer available" do
      ENV['PATH'].should_not include("mplayer")
    end
    
    before do
      @subject = MainWindow.new
      @subject.stub!(:choose_dvd_drive) {
        ["mock_dvd_drive", "Volume", "19d121ae8dc40cdd70b57ab7e8c74f76"] # happiest baby on the block
      }
      @subject.stub!(:get_mencoder_commands) { |*args|
        args[-4].should match(/abc/)
        @args = args
        'sleep 0.1'
      }
      @subject.stub!(:new_filechooser) {
        FakeFileChooser.new
      }
      @subject.stub!(:get_drive_with_most_space_with_slash) {
        "e:\\"
      }
      @subject.stub!(:show_blocking_message_dialog) { |*args|
        @show_blocking_message_dialog_last_args = args
      }
      @subject.stub!(:get_user_input) {'01:00'}
      @subject.stub!(:system_blocking) { |command|
        @system_blocking_command = command
      }

      @subject.stub!(:system_non_blocking) { |command|
        @command = command
        Thread.new {} # fake out the return...
      }
      @subject.stub!(:open_file_to_edit_it) {}
    end
    
    after do
      @subject.background_thread.join if @subject.background_thread
    end

    class FakeFileChooser
      def set_title x
      end
      def set_file y
      end
      def go
        'abc'
      end
    end
    
    # name like :@rerun_previous
    def click_button(name)
      @subject.instance_variable_get(name).simulate_click
    end

    it "should be able to do a normal copy to hard drive, edited" do
      @subject.system_non_blocking "ls"
      @subject.do_copy_dvd_to_hard_drive(false).should == [false, "abc.fulli_unedited.tmp.mpg"]
      File.exist?('test_file_to_see_if_we_have_permission_to_write_to_this_folder').should be false
    end
    
    it "should have a good default title of 1" do
     @subject.get_title_track({}).should == "1"
     descriptors = {"dvd_title_track" => "3"}
     @subject.get_title_track(descriptors).should == "3"
    end
    
    it "should call through to explorer for the full thing" do
      @subject.do_copy_dvd_to_hard_drive(false)
      @subject.background_thread.join
      @args[-3].should == nil
      @system_blocking_command.should match /explorer/
      @system_blocking_command.should_not match /fulli/
    end
    
    it "should be able to return the full list if it already exists" do
      FileUtils.touch "abc.fulli_unedited.tmp.mpg.done"
      @subject.do_copy_dvd_to_hard_drive(false,true).should == [true, "abc.fulli_unedited.tmp.mpg"]
      FileUtils.rm "abc.fulli_unedited.tmp.mpg.done"
    end
    
    it "should call explorer for the we can't reach this path of opening a partial without telling it what to do with it" do
     @subject.do_copy_dvd_to_hard_drive(true).should == [false, "abc.fulli_unedited.tmp.mpg"]
     @subject.background_thread.join
     @args[-1].should == 1
     @args[-2].should == "01:00"
     @command.should match /smplayer/
     @command.should_not match /fulli/
    end

    def prompt_for_start_and_end_times
      @subject.instance_variable_get(:@preview_section).simulate_click
      @args[-1].should == 1
      @args[-2].should == "01:00"
      @subject.background_thread.join
      @command.should match /smplayer/
    end

    it "should prompt for start and end times" do
      prompt_for_start_and_end_times
    end
    
    it "should be able to rerun the latest start and end times with the rerun button" do
      prompt_for_start_and_end_times
      old_args = @args
      old_args.should_not == nil
      @args = nil
      click_button(:@rerun_preview).join
      @args.should == old_args
      @command.should match(/smplayer/)
    end
    
    it "if the .done file exists, it should directly call smplayer" do
      FileUtils.touch "abc.fulli_unedited.tmp.mpg.done"
      @subject.instance_variable_get(:@watch_unedited).simulate_click
      @command.should == "smplayer abc.fulli_unedited.tmp.mpg"
      FileUtils.rm "abc.fulli_unedited.tmp.mpg.done"
    end
    
    it "if the .done file does not exist, it should call smplayer ja" do
      @subject.stub!(:sleep) {} # speed this test up...
      @subject.instance_variable_get(:@watch_unedited).simulate_click.join
      @subject.after_success_once.should == nil
      @command.should_not == nil # scary timing spec!
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
    
    it "should play edl with elongated mutes" do
      temp_dir = Dir.tmpdir
      temp_file = temp_dir + '/mplayer.temp.edl'
      click_button(:@mplayer_edl).join
      wrote = File.read(temp_file)
      # normally "378.0 379.1 1\n"
      wrote.should include("380.1")
    end
    
    it "should only prompt for drive once" do
      count = 0
      @subject.stub!(:choose_dvd_drive) {
        raise 'bad' if count == 1
        count = 1
        ['drive', 'volume', '19d121ae8dc40cdd70b57ab7e8c74f76']
      }
      @subject.choose_dvd_and_edl_for_it
      @subject.choose_dvd_and_edl_for_it
      count.should == 1
    end
    
    it "should only prompt for save to filename once" do
      count = 0
      @subject.stub!(:new_filechooser) {
        count += 1
        FakeFileChooser.new
      }
      @subject.get_save_to_filename 'yo'
      @subject.get_save_to_filename 'yo'
      count.should == 1
    end
    
    it "should prompt you if you need to insert a dvd"
    
    
  end
  
end
