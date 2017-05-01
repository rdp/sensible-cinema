#!/usr/bin/env bash

mysql -uroot mysql < ./db/init.sql # read your creds from ./db/XXX if required

rm sessions/* # in case they were logged in as a "now nuked" user

# to *not* nuke one just run
# mysql -uXXX -p db_name
# and enter commands manually from bottom of init.sql
