mkdir recording
ffmpeg -f dshow -i video="screen-capture-recorder"  -vframes 10 -y recording/%%d.png