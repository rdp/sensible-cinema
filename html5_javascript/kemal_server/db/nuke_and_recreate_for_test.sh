#!/usr/bin/env bash

mysql -uroot mysql < ./db/init.sql # read your creds from ./db/XXX if required

# to *not* nuke one just run
# mysql -uXXX -p db_name
# and enter commands manually from bottom of init.sql
