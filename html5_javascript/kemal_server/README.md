Edited movie player server and client source playitmyway.org 

For some demo videos here: https://www.youtube.com/channel/UC0xpO-Fh-jSh7e_H17A8bgw
though there was a lot of pre-existing art (including edited youtube API/google, community editing) from years ago, see the sourceforge https://sourceforge.net/projects/sensible-cinema/files/demo_videos/

## Installation of server:

# Ubuntu/VM

 curl https://dist.crystal-lang.org/apt/setup.sh | sudo bash # enable crystal  
 sudo apt install crystal build-essential libssl-dev jhead imagemagick fish -y # need cookie key, sessions dir, ssl dev key  
 \# add swap, need 1.5G anyway...  
 sudo apt install mysql-server -y 
 sudo /etc/init.d/mysql start  # ubuntu 18.04 don't seem to need...
 follow instructions below to reset root password (may need to set password?sudo mysql_secure_installation)

# OS X

brew install crystal kqwait mysql@5.7 imagemagick pidof fish jhead
brew services start mysql@5.7  

# for both, after, also do this:

login to mysql, SET PASSWORD FOR root@localhost=PASSWORD('');
# or possibly ALTER USER 'root'@'localhost' IDENTIFIED BY ''; 
# or possibly ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
$ cp db/connection_string_local_box_no_commit.txt.template db/connection_string_local_box_no_commit.txt
$ touch this_is_development 
./db/nuke* 
shards install # may need shards 0.9.0?
