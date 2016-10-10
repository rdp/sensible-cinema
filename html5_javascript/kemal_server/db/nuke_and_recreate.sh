rm ./edit_descriptors/sqlite3_data.db
sqlite3 ./edit_descriptors/sqlite3_data.db < ./db/init.sql
sqlite3 ./edit_descriptors/sqlite3_data.db < ./db/001.sql
