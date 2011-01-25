taskkill /f /im mencoder.exe
taskkill /f /im ffmpeg.exe
call j %* bin\sensible-cinema.rb
taskkill /f /im mencoder.exe
taskkill /f /im ffmpeg.exe