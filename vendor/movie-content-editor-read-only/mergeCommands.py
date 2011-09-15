'''
Created on Feb 11, 2010

@author: S. Andrew Ning
'''

import sys
import operator

def merge(path,custom):
    """
    Merges an automatically generate mute file with a custom file containing mute/skip commands.
    
    @param path - path to the files
    @param custom - a custom edit file
    @return a dictionary of commands for vlc to execute
      the key is StartTime, a float that contains the StartTime for that portion of the timeline
      the value is a tuple (Playable, MuteOn)
      Playable is a Boolean that indicates if that section is Playable (i.e. should be skipped or not)
      MuteOn is a Boolean that indiciates if the section should be muted
    """
    
    # ------ open files --------
    try:
        fMute = open(path + "mute.txt", 'rU')
        fCustom = open(path + custom,'rU')
    except IOError:
        print("File not found") #TODO: add a more descriptive error
        sys.exit()
    # ---------------------------
    
    # -------- commands ------------
    mute = -1 # mute start and finish (only used for convenience in this module)
    muteS = 0 # mute start
    muteF = 1 # mute finish
    skip = 2  
    
    commands = dict([(0.00,(True,False))])
    # -----------------------------
    
    # ---- read in automatically generate mute times -----
    for line in fMute:
        separate = line.strip().split()
#        muteT = (mute,float(separate[0]),float(separate[1]))
        commands[float(separate[0])]=(True,True)
        commands[float(separate[1])]=(True,False)
    fMute.close()
    # ----------------------------------------------
    
    # ----- read in custom file -----------
    for line in fCustom:
        if (line == "\n"): break
        separate = line.strip().split()
        command = separate[0].lower()
        commands[float(separate[1])]=(command not in ("skip","s"),command in ("mute","m"))
        commands[float(separate[2])]=(True,False)
        sortedKeys = sorted(commands.keys())
        # this part takes care of any collisions, probably is smarter way to accomplish this
        for ind in range(sortedKeys.index(float(separate[1])),sortedKeys.index(float(separate[2]))):
            commands[sortedKeys[ind]] = (command not in ("skip","s"),command in ("mute","m"))
    # -------------------------------------
    
    
    # ---- remove redundancies------
    prev = None
    for key in sorted(commands.keys()):
        curr=commands[key]
        if curr == prev:
            del commands[key]
        prev = curr    

    
    return commands
