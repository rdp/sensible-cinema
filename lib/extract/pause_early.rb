start = 3600
start = 0
play_this = "dvdnav://1/d:"
play_this = "dvd://1/d:"
#play_this = "title00.ts"
play_this = "dvdout.mpg"
in_out = IO.popen("mplayer #{play_this} -ss #{start} -slave", 'w')
in_out.puts "pause"
loop { 
  incoming = STDIN.gets 
  in_out.puts incoming.strip
}