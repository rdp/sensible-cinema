require File.expand_path(File.dirname(__FILE__) + '/common')
load '../bin/sensible-cinema'

module SensibleSwing
  describe MainWindow do
  
    it "should auto-select a EDL if it matches a DVD's title" do
      MainWindow.new.single_edit_list_matches_dvd("BOBS_BIG_PLAN").should_not be nil
    end
    
    it "should not auto-select if you pass it nil" do
      MainWindow.new.single_edit_list_matches_dvd(nil).should be nil
    end
    
    it "should prompt if two EDL's match a DVD title" do
      MainWindow.const_set(:EDL_DIR, 'temp')
      FileUtils.rm_rf 'temp'
      Dir.mkdir 'temp'
      MainWindow.new.single_edit_list_matches_dvd("BOBS_BIG_PLAN").should be nil
      Dir.chdir 'temp' do
        File.binwrite('a.txt', "dvd_drive_label: BOBS_BIG_PLAN")
        File.binwrite('b.txt', "dvd_drive_label: BOBS_BIG_PLAN")
      end
      MainWindow.new.single_edit_list_matches_dvd("BOBS_BIG_PLAN").should be nil
    end
    
    it "should modify path to have mencder available, and ffmpeg, and download them on the fly" do
      ENV['PATH'].should include("mencoder")
    end
  
  end
end