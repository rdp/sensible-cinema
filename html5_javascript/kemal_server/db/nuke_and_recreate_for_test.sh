#!/usr/bin/env bash

# some might be mysql no sudo?

sudo mysql -uroot mysql < ./db/init.sql # read your creds from ./db/XXX if required
sudo mysql -uroot mysql -e "update users set is_admin=1;" # dev only thing :|
sudo mysql -uroot mysql -e "update users set editor=1;" # dev only thing :|

rm -f sessions/* # in case they were logged in as a "now nuked" user

# to *not* nuke one just run
# mysql -uXXX -p db_name
# and enter commands manually from bottom of init.sql
