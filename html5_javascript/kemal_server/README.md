Edited movie player server source playitmyway.org 

For some demo videos here: https://www.youtube.com/channel/UC0xpO-Fh-jSh7e_H17A8bgw
though there was a lot of pre-existing art (including edited youtube API/google, community editing) from years ago, see the sourceforge https://sourceforge.net/projects/sensible-cinema/files/demo_videos/

## Installation of server:

# Ubuntu
sudo apt install crystal build-essential libssl-dev jhead imagemagick fish # need cookie key, sessions dir, ssl dev key
sudo apt install mysql-server # create db/connectionXX file
sudo /etc/init.d/mysql start

# OS X
brew install crystal-lang kqwait mysql imagemagick pidof
brew services start mysql

touch this_is_development

./db/nuke*

shards install

./goXX
