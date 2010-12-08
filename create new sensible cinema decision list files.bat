@setlocal
@rem disable any local rubyopt settings...
@set RUBYOPT=
@echo This window will display lots of debug message output!
@cd sensible-cinema && java -cp "./vendor/cache/jruby-complete-1.5.5.jar" org.jruby.Main bin\sensible-cinema --create-mode || echo you need to install java first! please report back the error you see! && pause