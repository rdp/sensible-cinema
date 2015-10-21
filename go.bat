@rem NB that you can call it like go --debug, except you can't since there's no gems in a jruby-complete jar...TODO vendor it LOL
call java -jar vendor\jruby-complete.jar %* bin\sensible-cinema
