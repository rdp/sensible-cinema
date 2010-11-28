Currently it takes as input a list of "skippable" scenes, and a player description.
It then tracks whichever player you are using, and mutes or blanks out the system appropriately, 
during the scenes specified.

It works out of the box with the hulu and VLC players on windows.  It isn't hard to 
add new players, and probably wouldn't be too hard to add more operating systems etc.

== How to Use ==

Start playing your movie in its respective player, then startup sensible-cinema from
the command line thus:

     C:\> jruby -S sensible-cinema

It prompts you for an EL (Edit decision List) file (ex: bambi.txt), 
and then for a player file (ex: hulu_full_screen.txt).

Sensible-cinema will now run in a console window, screen tracking the player to monitor its position,
and react'ing appropriately.

It is presumed that you'll then minimize sensible-cinema and proceed to enjoy the movie.

You'll know that it's working if, when you change the time of your player (ex: dragging it to a new spot 
in the playback), the screen output in sensible-cinema's console should change to match the new time.

== How to install ==

First you'll need to install jruby (in case you haven't already), from http://www.jruby.org
Make sure you check the box "add it to my path" or something similar to that.

Next install the gem by either opening up the command window or hitting windows+r (run) and typing

       C:\> jruby -S gem install sensible-cinema 

  it's jruby only currently (since jruby allows for proper thread concurrency, has an easy GUI, and feels actually sane on windows).
  It could theoretically be ported to MRI 1.9.2, if anybody wanted to do so.
  Also if anybody would be interested in porting this to Linux I'd be happy to collaborate.
  
You can test that it's installed by running it (see above) and selecting the "example_edit_decision_list.txt", and 
choosing the hulu player.

It will proceed do a few "demo" mutes and blank outs.

== FAQ ==

Q. Can I watch movies this way on my TV, not just on my computer?

A. Maybe.  Or possible not yet, depending on your current hardware.
   Currently you'll either need to attach your computer to your TV
   (buy some long cables, or a new graphics card that matches your cables, etc.) 
   or get some computer that you can move closer to the TV to do the same 
   (ex: buy a used older laptop with s-video out, use that, or a laptop with DVI/HDMI would
   work with an HDMI TV).  If you're really aggressive you could run an ethernet cable from your computer, as well [1].
   I'd be happy to do a linux port of sensible-cinema if anybody requests it, for use with 
   their dedicated TV computer.
   There has also been some work toward getting ones computer to stream "live" to your existing wii/ps3/xbox.
   Message me if you're interested in trying it out (testers wanted--plus I'll only work on it if there's demand)!   

Q. What movies does this work with?

A. Any that you program it for :) (Assuming the computer player is compatible, which most probably are.)

Q. What movies are freely available to watch online?

A. Not many are available free (hulu, youtube have a few). Netflix has quite a few with its default subscription.  
   You can of course use it with any existing DVD, or rent or borrow DVD's and watch them using sensible-cinema.

Q. Why does my mouse bounce up and down while sensible-cinema is going?

A. This enables your player to keep its on-screen time tracker, which in turn allows sensible-cinema to track where 
   you're at.  Message me if this bugs you too much and we'll see what we can do about it.

[1] http://ps3mediaserver.org/forum/viewtopic.php?f=6&t=5731#p34279

== Advanced Usage ==

You could specify the scene descriptions list and player list on the command-line, if you don't want to have
to pick them each time, like:

     C:\> jruby -S sensible-cinema edit_decision_list.yml player_description.yml

Also if you specify "test" for the scene descriptions file, it will pause 4s, take a snapshot of the player, then exit.
You can also specify -v or -t if you want to enable more verbose (chatty) output.

== Thanks ==

Thanks to Jarmo for the win32-screenshot gem, mini_magick gem authors, jruby guys, etc.  
The combination made programming this actually something of a pleasure.
