# stand alone file
start = 33.26
#play_this = "g:\\Video\\Sintel_NTSC\\Sintel_NTSC-2.m4v"
play_this = "dvdnav://1/d:"
#play_this = "dvd://1/d:"
#play_this = "title00.ts"
#play_this = "dvdout.mpg"
in_out = IO.popen("mplayer -vo direct3d -osdlevel 2 #{play_this} -ss #{start} -slave -font c:\\windows\\fonts\\arial.ttf", 'w')
in_out.puts "pause"
loop { 
  p 'accepting from console'
  incoming = STDIN.gets 
  in_out.puts incoming.strip
}