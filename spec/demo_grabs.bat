@rem raw

call mencoder dvdnav://1 -endpos 180 -nocache -sid 1000 -of mpeg  -oac copy -ovc copy -o raw.mpg -dvd-device d:\

@rem mp4 i's'

call mencoder dvdnav://1 -endpos 180 -alang en -nocache -sid 1000 -oac copy -ovc lavc -lavcopts keyint=1 -ovc lavc -o mp4.avi -dvd-device f:\ 


@rem mpeg2 i's'

call mencoder dvdnav://1 -endpos 180 -alang en -nocache -sid 1000 -oac copy -ovc lavc -lavcopts vcodec=mpeg2video:vrc_buf_size=1835:vrc_maxrate=9800:vbitrate=5000:keyint=1:vstrict=0:acodec=ac3:abitrate=192:aspect=4/3 -ofps 30000/1001 -ovc lavc -o mpegfulli.avi -dvd-device f:\ 

@rem unfortunately it re-encodes it with our [lackluster] mpeg2 encoding...I think...



ffmpeg -i raw.mpg -vcodec h264 -cqp 1 -intra -coder ac -an output.mp4



    @rem -lavcopts vcodec=mpeg2video:vrc_buf_size=1835:vrc_maxrate=9800:vbitrate=5000:keyint=1:vstrict=0:acodec=ac3:abitrate=192:aspect=4/3 -ofps 30000/1001



call ffmpeg -i to_here.avi.fulli.tmp.avi -vcodec copy -acodec copy  -ss 0 -t 0.999 to_here.avi.1.avi
call ffmpeg -i to_here.avi.fulli.tmp.avi -vcodec copy -acodec ac3 -vol 0  -ss 1.0 -t 0.999 to_here.avi.2.avi
call ffmpeg -i to_here.avi.fulli.tmp.avi -vcodec copy -acodec copy  -ss 3.0 -t 3.999 to_here.avi.3.avi
call ffmpeg -i to_here.avi.fulli.tmp.avi -vcodec copy -acodec ac3 -vol 0  -ss 7.0 -t 4.999 to_here.avi.4.avi
call ffmpeg -i to_here.avi.fulli.tmp.avi -vcodec copy -acodec copy  -ss 12.0 -t 999987.999 to_here.avi.5.avi
call mencoder to_here.avi.1.avi to_here.avi.2.avi to_here.avi.3.avi to_here.avi.4.avi to_here.avi.5.avi -o to_here.avi.avi -ovc copy -oac copy
@rem call mencoder -oac lavc -ovc lavc -of mpeg -mpegopts format=dvd:tsaf -vf scale=720:480,harddup -srate 48000 -af lavcresample=48000 -lavcopts vcodec=mpeg2video:vrc_buf_size=1835:vrc_maxrate=9800:vbitrate=5000:keyint=18:vstrict=0:acodec=ac3:abitrate=192:aspect=16/9 -ofps 30000/1001  to_here.avi.1.avi to_here.avi.2.avi to_here.avi.3.avi to_here.avi.4.avi to_here.avi.5.avi -o to_here.avi.avi
@rem del to_here.avi.fulli.tmp.avi
@rem del to_here.avi.1.avi to_here.avi.2.avi to_here.avi.3.avi to_here.avi.4.avi to_here.avi.5.avi
echo wrote to to_here.avi.avi