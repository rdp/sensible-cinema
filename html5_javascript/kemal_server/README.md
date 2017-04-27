Edited movie player server source playitmyway.org 

For some demo videos here: https://www.youtube.com/channel/UC0xpO-Fh-jSh7e_H17A8bgw
though there was a lot of pre-existing art (including edited youtube API/google, community editing) from years ago, see the sourceforge https://sourceforge.net/projects/sensible-cinema/files/demo_videos/

## Installation of server:

# ubuntu
apt install jhead imagemagick # etc...

# os x
brew install crystal-lang kqwait mysql imagemagick pidof
  brew services start mysql

./db/init

shards install
./goXX
