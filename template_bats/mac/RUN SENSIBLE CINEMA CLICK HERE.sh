#!/usr/bin/env bash
cd ../sensible-cinema
java -Xdock:name="Sensible Cinema" -Xdock:icon="./vendor/profs.png" -cp "./vendor/jruby-complete-1.6.2.jar" org.jruby.Main bin/sensible-cinema $1 $2 $3 || (echo ERROR. Please look for error message, above, and report back the error you see, or fix it && read -p "Press any key to continue...")

