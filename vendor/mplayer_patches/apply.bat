rem assumes you in mplayer/ dir
rem known to work with r 34396, ffmpeg  eb4fc6acfede7ced5737c5bf023f
patch -p0 <  %~dp0/mplayer_edl.diff
cd libdvdnav
echo 'just retype last part of name'
patch -p0 <  %~dp0/libdvdnav/2905259c3b45529b3d8dedba572b6e4f67a2d8f4.diff
patch -p0 <  %~dp0/libdvdnav/83f1c9256f500285e46f1e44bcc74ffce90159db.diff
patch -p0 <  %~dp0/libdvdnav/eb91fb74680d30322461a1b9e425918ad4e2b2df.diff
@rem below actually work
patch -p0 <  %~dp0/libdvdnav/non_strict.diff
patch -p1 <  %~dp0/libdvdnav/jump_to_time.diff
cd ..