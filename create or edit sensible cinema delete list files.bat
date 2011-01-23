@setlocal
@rem disable any local rubyopt settings...
@set RUBYOPT=
@echo This window will display lots of debug message output!
@java -version || echo need to install java first && pause
@cd sensible-cinema && java -cp "./vendor/cache/jruby-complete-1.5.5.jar" org.jruby.Main bin\sensible-cinema.rb --create-mode || echo ERROR. Please look for error message, above, and report back the error you see, or fix it && pause
@taskkill /f /im mencoder.exe