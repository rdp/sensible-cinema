vlc --sub-filter "logo{file='transparent.png,10000,g:\video\sintel_ntsc\cone.png,5000,128,fake.png,20000,128;'}" dvd://d:\@2 --stop-time=30
vlc --sub-filter "logo{file='cone.png,500000,128;transparent.png,1000,128'}" dvd://d:\@2 --stop-time=30

@rem dvd://d:\@2  :start-time=10 :stop-time=20 dvd://d:\@2  :start-time=20 :stop-time=25 :sub-filter=logo{file=g:\video\sintel_ntsc\cone.png,transparency=128} dvd://d:\@2 :start-time=25 :stop-time=30 vlc://quit




vlc dvd://d:\@2 :start-time=70 :stop-time=75 :sub-filter=logo{file=g:\video\sintel_ntsc\cone.png,transparency=128} 
 