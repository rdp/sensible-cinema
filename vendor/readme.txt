                     SetPriority README
                  http://gilchrist.ca/jeff/
                       Jeff Gilchrist

May 1, 2004

NOTE: ** THIS IS BETA SOFTWARE, USE AT YOUR OWN RISK AND PLEASE
         REPORT ALL BUGS TO ME **

What is SetPriority?
--------------------
SetPriority is a Windows command line program that will allow you
to view or change both the process priority and thread priority of
a running program.  NOTE: It does not work on Windows services.

License/Disclaimer
------------------
This software is freeware and can be freely distributed.  Use at your
own risk.  I take no responsibility for anything that happens to your
equipment.  Please keep this README file with the SetPriority
executable if you are going to re-distribute it.

History
-------
v0.2 (May 1, 2004)  - Initial public release.


Usage
-----
Run SetPriority.exe -h for the help listing.

===================================================================
Usage: setpriority [-g] [-p#] [-t#] [-lowest] <PID>

 -g  : get process information only then exit
 -h  : this help screen
 -p# : where # is new process priority class (default: 64 [IDLE])
 -t# : where # is new thread priority (default: -15 [Lowest])
 -lowest : sets lowest possible priority

Example: setpriority -p32 -t-2 342
         setpriority -lowest 342
         setpriority -g 342


              Process      Thread
              -------      ------
RealTime   :  256          15
High       :  128          2
AboveNormal:  32768        1
Normal     :  32           0
BelowNormal:  16384        -1
Idle       :  64           -2
Lowest     :  N/A          -15
===================================================================

In order to view or change the priority of a running program, you
must first determine its PID (Process ID).  You can do this by
opening the Windows Task Manager and clicking on the "Processes"
tab.  You should then see a list of running processes on your
Windows machine.  If you do not see a "PID" column, click on the
"View" menu, then "Select Columns".  Check the "PID (Process
Identifier" checkbox, then click on "OK".  You should now see a
PID column in the "Processes" tab.

Locate the name of the process you are interested in viewing or
changing the priority of.  Beside that name in the PID column you
will see its associated PID.

If the PID for the process you are interested in is 3320, to view
the current priority settings you would use the following command
line:

C:\>setpriority -g 3320

The program would report something like:

===================================================================
SetPriority v0.2   by: Jeff Gilchrist
                   http://gilchrist.ca/jeff/


Process ID (PID): 3320
Current Priority Class : 64
Current Thread Priority: -15


              Process      Thread
              -------      ------
RealTime   :  256          15
High       :  128          2
AboveNormal:  32768        1
Normal     :  32           0
BelowNormal:  16384        -1
Idle       :  64           -2
Lowest     :  N/A          -15
===================================================================

Use the legend at the bottom of the output to determine what the
priority codes mean.  A priority class of 64 means that the process
is running at "Idle" priority.  The thread priority of -15 means
the thread is running at "Lowest" priority.  This program is
therefore running at the lowest possible priority.  Some programs
may have more than one thread and if that is the case, you will see
multiple thread priorities listed in the output.

If you wanted to modify the priority so the program runs at the
Normal priority setting you would run:

C:\>setpriority -p32 -t0 3320

Currently there is no way to set individual thread priorities so if
the program has multiple threads, all threads will be set to the
thread priority you specify on the command line.


Bugs/Contact
------------
If you would like to report any bugs or contact me related to the
software you can reach me via e-mail at:  jeff [at] gilchrist.ca
