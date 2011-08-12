call vlc --sub-filter "logo{file='transparent.png,256'}" dvd://d:\@2 --stop-time=56 --start-time=45 vlc://quit
call vlc --sub-filter "logo{file='cone.png,256'}" dvd://d:\@2 --start-time=56 --stop-time=57 vlc://quit
call vlc --sub-filter "logo{file='transparent.png,256'}" dvd://d:\@2 --start-time=57 --stop-time=65 vlc://quit
call vlc --sub-filter "logo{file='cone.png,256'}" dvd://d:\@2 --start-time=65 --stop-time=74.5 vlc://quit
call vlc dvd://d:\@2 --start-time=74.5 vlc://quit


  "00:00:56.0" , "00:00:57.0", "violence", "knife stabbing",
  "00:01:05.0" , "00:01:14.5", "violence", "stab through",





@rem working: -> vlc --sub-filter "logo{file='cone.png,5000,128;transparent.png,2000,128;cone.png,10000,256'}" dvd://d:\@2 --stop-time=30
@rem vlc --sub-filter "logo{file='cone.png,500000,128;transparent.png,1000,128'}" dvd://d:\@2 --stop-time=30

@rem dvd://d:\@2  :start-time=10 :stop-time=20 dvd://d:\@2  :start-time=20 :stop-time=25 :sub-filter=logo{file=g:\video\sintel_ntsc\cone.png,transparency=128} dvd://d:\@2 :start-time=25 :stop-time=30 vlc://quit




@rem vlc dvd://d:\@2 :start-time=70 :stop-time=75 :sub-filter=logo{file=g:\video\sintel_ntsc\cone.png,transparency=128} 
 