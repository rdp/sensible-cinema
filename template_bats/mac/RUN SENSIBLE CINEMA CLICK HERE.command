#!/usr/bin/env bash
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR/../clean-editing-movie-player
java -Xdock:name="Clean Editing Movie Player" -Xdock:icon="./vendor/profs.png" -cp "./vendor/jruby-complete.jar" org.jruby.Main bin/sensible-cinema $1 $2 $3 || (echo ERROR. Please look for error message, above, and report back the error you see, or fix it && read -p "Press any key to continue...")

