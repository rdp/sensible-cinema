@echo Welcome to the Clean Editing Movie Player...
@IF NOT EXIST clean-editing-movie-player\VENDOR\CACHE GOTO NOVENDORDIR
@echo This window will display lots of debug output 
@echo   (you can just ignore this window or minimize it, but do have to leave it open)
@setlocal

@set PATH=%WINDIR%\syswow64;%PATH%
@rem add in JAVA_HOME just for fun/in case
@set PATH=%PATH%;%JAVA_HOME%\bin

@rem disable any local rubyopt settings, just in case...
@set RUBYOPT=
@rem check for java installed...we will be needing that :)
@call java -version > NUL 2>&1 || echo need to install java JRE first please install it from java.com && pause && GOTO DONE

@cd clean-editing-movie-player
@call java -cp "./vendor/jruby-complete.jar" org.jruby.Main bin\sensible-cinema %* || echo ERROR. Please look for error message, above, and report back the error you see, or fix it && pause

@rem taskkill /f /im mencoder.exe ???

GOTO DONE

:NOVENDORDIR
@echo "it appears you downloaded sensible cinema straight from github--please download it instead from https://sourceforge.net/projects/sensible-cinema/files/ for it to work properly"
@pause
@start https://sourceforge.net/projects/sensible-cinema/files

@rem fall through

:DONE
