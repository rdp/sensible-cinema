#! /usr/bin/python
import vlc
import sys
import time
from threading import Thread, Event
from bisect import bisect
from subtitle import readSrt
from mergeCommands import merge

DEBUG = True

def sendDebug(msg, newline=1):
    global DEBUG
    if DEBUG:
        if newline:
            print ' '
        print msg
        
@vlc.callbackmethod
def playPauseCallback(event, data):
    #do we need to do anything else here?
    sendDebug('Got a callback')
    thread1.event.set()
    
@vlc.callbackmethod
def positionCallback(event, data):
    #should probably do something here
    thread1.event.set()
    

# For now I need to define the path, I commented out so it should work for you guys
#path = 'C:\Users\cuff\Documents\moonlight\movie-content-editor\movie_editor\\'
path = ''


badwordsFile = "badwords.txt"
movieFile = "Kung Fu Panda.m4v"
subtitleFile = "panda.srt"
blankFile = "blank.srt"
customFile = "panda_custom.txt"

# ------  create edited subtitle file ------
subtitleEdit = readSrt(path,subtitleFile,badwordsFile)
# --------------------------------------------

# ------- create list of commands ----------
commands = merge(path,customFile)
# -----------------------------------------




# -------- Load and start movie ----------------
"""Set up the system independent movie interface. For windows, we can just use the 
default Qt interface. For mac, we have to use our custom built interface. Nothing is
currently implemented for Linux"""

if sys.platform == 'darwin':
    d='/Applications/VLC.app/Contents/MacOS'
    args1 = "-I dummy --verbose=-1 --ignore-config --plugin-path="
    if sendDebug:
        args1 = "-I dummy --verbose=1 --ignore-config --plugin-path="
    vlc_args = (args1 + d + "/modules --vout=minimal_macosx --opengl-provider=minimal_macosx")
    instance = vlc.Instance(vlc_args)
else:
    instance = vlc.Instance()
    instance.add_intf("qt")


    
media = instance.media_new(path + movieFile)
player = instance.media_player_new()
player.set_media(media)

if sys.platform == 'darwin':
    from PyQt4 import QtGui
    from VLCMacVideo import MacPlayer
    app = QtGui.QApplication(sys.argv)
    mplayer = MacPlayer(player)

events = vlc.EventType

manager = player.event_manager()
mediaManager = media.event_manager()
manager.event_attach(events.MediaPlayerPaused,playPauseCallback,None)
#manager.event_attach(events.MediaPlayerPausableChanged,dummy,None)
manager.event_attach(events.MediaPlayerPlaying,playPauseCallback,None)
#manager.event_attach(events.MediaPlayerTimeChanged,dummy,None)
#mediaManager.event_attach(events.MediaStateChanged,dummy,None)
manager.event_attach(events.MediaPlayerPositionChanged,positionCallback,None)
player.play()
# -------------------------------------------------

# I use this for testing with Panda
player.set_time(33000)



# ------------- subclass off of Thread ---------------
class editThread (Thread):
    event = Event()    

    def run ( self ):

        sendDebug(commands)
        #puts the keys in order - the keys are the time stamps of when the player state needs to change
        sortedKeys = sorted(commands.keys())
        sendDebug(sortedKeys)
        currKey = 0.0
        nextKey = 0.0
        while True:
            #if player isn't playing, wait for it to start
            if not player.is_playing:
                self.event.clear()
                self.event.wait()
                
            #clear any old events so they don't continue to trigger a response                
            self.event.clear()
            
            now = float(player.get_time())/1000.0

            # find the correct portion of the timeline

            # if we're actually at a new part of the timeline, then change the state
            if not (currKey<= now <nextKey):
                nextInd = bisect(sortedKeys,now)
                nextKey = sortedKeys[nextInd]
                sendDebug('New State')
                currInd = nextInd - 1
                currKey = sortedKeys[currInd]
                sendDebug(currKey)    
                
                #Get the Playable and MuteOn attributes for the current state and act on them
                Playable,MuteOn = commands[currKey]
                if not Playable:
                    skip(nextKey*1000)
                    
                if MuteOn:
                    onMute()
                else:
                    offMute()



            # wait for the next portion of the timeline, or for an user event to occur
            # this is probably unnecessary because the PositionChanged event seems to occur
            # every 0.5 s or so
            waitTime = nextKey - float(player.get_time())/1000.0
            if waitTime > 30.0:
                self.event.wait(waitTime - 30.0)
                waitTime = nextKey - float(player.get_time())/1000.0
            self.event.wait(waitTime)
                                
                
        return
        
# ------------------------------------------------------

# ------- methods -------------------------
def onMute ():
    sendDebug("Muting started %s" % (float(player.get_time())/1000.0))
    player.video_set_subtitle_file(path + subtitleEdit)
    instance.audio_set_mute(1)
    return
    
def offMute ():
    sendDebug("Muting stopped %s" % (float(player.get_time())/1000.0))
    player.video_set_subtitle_file(path + blankFile)
#    player.video_set_spu("Testing SPU")
    instance.audio_set_mute(0)
    return

def skip(tSkip):
    sendDebug('Skipping ahead')
    player.set_time(long(tSkip))
    return

def stop(player):
    if sys.platform != 'darwin':
        player.stop()
    sys.exit()
# --------------------------------------------

thread1 = editThread()
thread1.start()


if sys.platform == 'darwin':
    app.exec_()
else:
    # this is temporary just so player doesn't go on for long time
    #time.sleep((80-player.get_time()/1000))
    instance.wait()

stop(player)


