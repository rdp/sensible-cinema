@rem with track 1, DVD drive d:\
mplayer -benchmark -endpos 10 dvdnav://1/d: -vo null -nosound 2>&1 > output2.txt
@rem then examine output2.txt
