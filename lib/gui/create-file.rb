module SensibleSwing
  
  class MainWindow
    
    def sanity_check_file filename
	  check_for_ffmpeg_installed
      out = `ffmpeg -i #{filename} 2>&1`
      print out
      unless out =~ /Duration.*start: 0.00/ || out =~ /Duration.*start: 600/
        show_blocking_message_dialog 'file\'s typically have the movie start at zero, this one doesn\'t? Please report.' + out
        raise # give up, as otherwise we're 0.3 off, I think...hmm...
      end
      if filename =~ /\.mkv/i
        show_blocking_message_dialog "warning .mkv files from makemkv have been known to be off timing wise, please convert to a .ts file using tsmuxer first if it did come from makemkv"
      else
        if filename !~ /\.(ts|mpg|mpeg)$/i
          show_blocking_message_dialog("warning: file #{filename} is not a .mpg or .ts file--conversion may not work properly all the way [produce a truncated file], but we can try it if you want...") 
        end
      end
    end
    
  end
end
