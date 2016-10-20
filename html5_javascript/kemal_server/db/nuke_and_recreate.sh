#!/usr/bin/env bash
#rm ./edit_descriptors/sqlite3_data.db
#sqlite3 ./edit_descriptors/sqlite3_data.db < ./db/init.sql

mysql -uroot mysql < ./db/init.sql
