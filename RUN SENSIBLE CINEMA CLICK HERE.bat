@echo Welcome to Sensible Cinema.
@echo This window will display lots of debug message output!
@setlocal
@rem disable any local rubyopt settings...
@set RUBYOPT=
@rem check for java installed...we will need that :)
@java -version > NUL 2>&1 || echo need to install java JRE first && pause
@cd sensible-cinema && java -cp "./vendor/cache/jruby-complete-1.5.5.jar" org.jruby.Main bin\sensible-cinema %* || echo ERROR. Please look for error message, above, and report back the error you see, or fix it && pause
@rem taskkill /f /im mencoder.exe