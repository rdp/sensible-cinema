Currently the experimental screen tracking edited player (bin\sensible-cinema-cli) prompts for an edit list
and a player description.

It then tracks whichever player you are using, by using OCR on its timestamps (moves the mouse every 
so often to and mutes or blanks out the system appropriately, during the scenes specified).

It works out of the box with the hulu and VLC players on windows.  It isn't hard to 
add new players, and probably wouldn't be too hard to add more operating systems etc.

== How to Use ==

Start playing your movie in its player, then start sensible-cinema-cli

It prompts you for an EDL (Edit decision List) file (ex: bambi.txt), 
and also for a player description file (ex: hulu_full_screen.txt).

Sensible-Cinema will now run in its console window, screen tracking the player to monitor its position,
and react appropriately (mute system volume, or overlay screen with a black window to cover content playback).

It is presumed that you'll then minimize sensible-cinema and enjoy the movie.

You'll know that it's working if, when you change the time of your player (ex: dragging it to a new spot 
in the playback), the screen output listed in sensible-cinema's console changes to match the new time.

You can test that it's installed by running it (see above) and selecting the "example_edit_decision_list.txt", and 
choosing the hulu player.

It will show you a few "demo" mutes and blank outs.

== FAQ ==

Q. What movies are freely available to watch online?

A. Not many are available free (hulu, youtube have a few). Netflix has quite a few now for money.  
   You can of course use SC with DVD's (which you own, borrow, or rent).
   (If they have an edit list (or you could create your own for them if not...).)

Q. Why does my mouse bounce up and down while sensible-cinema is going?

A. This enables your player to keep its on-screen time tracker, which in turn allows sensible-cinema to track where 
   you are at regarding time position.  Message me if this bugs you too much and we'll see what we can do to alleviate it.
  
To create a new player, basically you have to create a new descriptor, then add unit tests for all of its digits, to make sure they OCR well :(
A bit convoluted, I agree.  Ping me if you want one added.