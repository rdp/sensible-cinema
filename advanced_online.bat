#@rem NB that you can call it like go --debug, except you can't since there's no gems in a jruby-complete jar...
# TODO -v
java -jar vendor/jruby-complete.jar $1 $2 $3 bin/sensible-cinema  --online-player-mode --go --advanced
#@ j --debug  %* bin\sensible-cinema  --online-player-mode --advanced
