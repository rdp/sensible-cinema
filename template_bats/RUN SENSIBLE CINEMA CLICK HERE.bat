@echo Welcome to Sensible Cinema...
@IF NOT EXIST sensible-cinema\VENDOR\CACHE GOTO NOWINDIR
@echo This window will display lots of debug output (you can just ignore this window)
@setlocal
@rem disable any local rubyopt settings, just in case...
@set RUBYOPT=
@rem check for java installed...we will be needing that :)
@java -version > NUL 2>&1 || echo need to install java JRE first please install it from java.com && pause && GOTO DONE
@cd sensible-cinema && java -cp "./vendor/cache/jruby-complete-1.5.5.jar" org.jruby.Main bin\sensible-cinema %* || echo ERROR. Please look for error message, above, and report back the error you see, or fix it && pause
@rem taskkill /f /im mencoder.exe
GOTO DONE

:NOWINDIR
@echo "it appears you downloaded sensible cinema straight from github--please download it instead from http://rogerdpack.t28.net/sensible-cinema/"
@pause
@start http://rogerdpack.t28.net/sensible-cinema
GOTO DONE

:DONE