
module SensibleSwing
  
  class MainWindow < JFrame

    SideBySide = 'side_by_side' # 'xbmc' or 'smplayer'
    
    def select_new_sxs_style
      answer = show_select_buttons_prompt 'Select EDL file style creation for this program', :yes => 'Smplayer style', :no => 'XBMC style'
      if answer == :yes
        LocalStorage[SideBySide] = 'smplayer'
      elsif answer == :no
        LocalStorage[SideBySide] = 'xbmc'
      else
        show_blocking_message_dialog 'please choose one--smplayer if you don\'t know'
        select_new_sxs_style
      end
        
    end

#      new_jbutton("Select side by side EDL file style (smplayer vs. XBMC)") do
#        select_new_sxs_style # TODO
#      end


  end
end
