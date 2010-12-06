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

    it "should prompt if two EDL's match a DVD title" do
      old_edl = MainWindow::EDL_DIR
      MainWindow.const_set(:EDL_DIR, 'temp')
      FileUtils.rm_rf 'temp'
      Dir.mkdir 'temp'
      MainWindow.new.single_edit_list_matches_dvd("BOBS_BIG_PLAN").should be nil
      Dir.chdir 'temp' do
        File.binwrite('a.txt', "\"disk_unique_id\" => \"abcdef1234\"")
        File.binwrite('b.txt', "\"disk_unique_id\" => \"abcdef1234\"")
      end
      MainWindow.new.single_edit_list_matches_dvd("abcdef1234").should be nil
      MainWindow.const_set(:EDL_DIR, old_edl)
    end

    it "should modify path to have mencder available, and ffmpeg, and download them on the fly" do
      ENV['PATH'].should include("mencoder")
    end

    before do
      @subject = MainWindow.new
      @subject.stub!(:choose_dvd_drive) {
        ["drive", "volume", "19d121ae8dc40cdd70b57ab7e8c74f76"] # happiest baby on the block
      }
      @subject.stub!(:generate_and_run_bat_file) { |*args|
        args[0].should == 'abc'
        @args = args
      }
      @subject.stub!(:new_filechooser) {
        FakeFileChooser.new
      }
      @subject.stub!(:get_drive_with_most_space_with_slash) {
        "e:\\"
      }
      @subject.stub!(:show_blocking_message_dialog) {}
      @subject.stub!(:get_user_input) {'01:00'}
      @subject.stub!(:system_non_blocking) { |command|
        @command = command
        Thread.new {} # fake out the return...
      }
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
    
    it "should be able to do a normal copy to hard drive, edited" do
      @subject.do_copy_dvd_to_hard_drive(false).should == [false, "abc.fulli.tmp.avi"]
    end
    
    it "should be able to return the full list if it already exists" do
      FileUtils.touch "abc.fulli.tmp.avi.done"
      @subject.do_copy_dvd_to_hard_drive(false,true).should == [true, "abc.fulli.tmp.avi"]
      FileUtils.rm "abc.fulli.tmp.avi.done"
    end
    
    it "should prompt for start and end times" do
      @subject.do_copy_dvd_to_hard_drive(true).should == [false, "abc.fulli.tmp.avi"]
      @args[-1].should == 1
      @args[-2].should == "01:00"
    end
    
    it "if the .done file exists, it should directly call smplayer" do
      FileUtils.touch "abc.fulli.tmp.avi.done"
      @subject.instance_variable_get(:@watch_unedited).simulate_click
      @command.should == "smplayer abc.fulli.tmp.avi"
      FileUtils.rm "abc.fulli.tmp.avi.done"
    end
    
    it "if the .done file does not exist, it should not call mplayer" do
      @subject.instance_variable_get(:@watch_unedited).simulate_click
      @command.should == nil
    end

  end
end
