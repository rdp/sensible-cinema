#!/usr/bin/env bash

mysql -uroot mysql < ./db/init.sql # read your creds from ./db/XXX if required
mysql -uroot mysql -e "update users set admin=1;" # dev only thing :|
mysql -uroot mysql -e "update users set editor=1;" # dev only thing :|

rm -f sessions/* # in case they were logged in as a "now nuked" user

# to *not* nuke one just run
# mysql -uXXX -p db_name
# and enter commands manually from bottom of init.sql
