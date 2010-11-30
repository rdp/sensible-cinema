require File.expand_path(File.dirname(__FILE__) + '/common')
load '../bin/sensible-cinema'

module SensibleSwing
  describe MainWindow do
  
    it "should auto-select an EDL if the title matches" do
      MainWindow.new.single_edit_list_matches_dvd("BOBS_BIG_PLAN").should_not be nil
    end
    
    it "should prompt if two match" do
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
    
    it "should modify path to have VLC available" do
      ENV['PATH'].should include("VideoLAN")
    end
  
  
  end
end