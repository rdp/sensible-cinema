'''
Created on Feb 11, 2010
@author: S. Andrew Ning
'''

import sys

def readSrt(path,subtitles,filterList):
    """
    Edits a subtitle *.srt file.
    
    @param - path where file is located (I need to figure out how to avoid this with Pydev
    @param subtitles - the *.srt file
    @param filterList - text file containing words we want to filter out
    @return the name of the edited subtitle file
    - writes to disk "mute.txt" which contains instructions on when to mute in the
    form START_TIME END_TIME \n
    - also writes out *_edit.srt which is a new subtitle file
    with all filtered words replaced with an asterisk.
    """
    
    # ------ open files --------
    name = subtitles.split('.')
    editFile = name[0] + "_edit.srt"
    try:
        fin = open(path + subtitles, 'rU')
        fbad = open(path + filterList,'rU')
        fout = open(path + 'mute.txt','w')
        fedit = open(path + editFile,'w')
    except IOError:
        print("File not found") #TODO: should be more specific here
        sys.exit()
    # ---------------------------
    
    # --- create badwords list -----
    badWords = []
    for line in fbad:
        badWords.append(line[:-1]) # remove newline character
    fbad.close()
    # ------------------------------

    
    # loop through subtitles
    while True:
        # ---- read caption number -----
        num = fin.readline()
        if (num == ''): break # end of file check
        fedit.write(num)
        # -----------------------------
        
        # ----- read time span of caption ----
        times = fin.readline()
        fedit.write(times)
        # -------------------------------------
        
        # -- read subtitles and decide whether or not to edit ----
        reject = False
        line = fin.readline()
        while (line != '\n'): # blank line between sections
            for word in badWords:
                if word in line:
                    line = line.replace(word,'*')
                    reject = True
    
            fedit.write(line)
            line = fin.readline()

        fedit.write(line) # add blank line back in
        # ----------------------------------------------------

        # --- convert time to seconds and save --------
        if reject:
            tStart = (float(times[0:2])*3600.0 + 
                      float(times[3:5])*60.0 + 
                      float(times[6:8]) + 
                      float(times[9:12])/1000.0)
            tFinish = (float(times[17:19])*3600.0 + 
                      float(times[20:22])*60.0 + 
                      float(times[23:25]) + 
                      float(times[26:29])/1000.0)
                    
            fout.write(str(tStart) + "\t" + str(tFinish) + "\n");
        # --------------------------------------------

    fin.close()
    fedit.close()
    fout.close()
    
    return editFile

