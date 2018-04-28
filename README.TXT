This is a README description for Sensible Cinema, the Clean Editing Movie Player (CEM Player)

For installation/download instructions, see http://cleaneditingmovieplayer.inet2.org/

===

	CEM Player allows you to use pre-programmed edit lists (e.g. Edit Decision Lists [2]) to watch movies that you own. I.e. you can watch a DVD while "muting out" or skipping certain
scenes, deemed objectionable. This allows you to sit back and relax as you watch a more "sanitized" showing of your DVD.

	It is currently in alpha/beta, and is free (probably forever, under LGPL license currently). It also includes a library of EDL's that go along with various DVD's.  We need
volunteers/contributors to help it grow!

	To use:
1. Install Sensible Cinema.
2. Insert an original DVD that you want to edit.
3. Run sensible cinema. It will pop up some windows where you choose what to do (watch edited, create a new EDL file, etc.).

Note: please install from the zip files at https://bintray.com/rdp/sensible-cinema/sensible-cinema and not from github's "download" button.

	CEM Player has a few "realtime viewing" options available, based on some freely available open source popular video players. [3]

	On a moral note, just because an edited video lacks profanity/sex scenes...does not automatically make it a wholesome experience. CEM Player does not necessarily "a clean movie make of
a dirty one" even if it can cut profanity. Don't watch it if it's not uplifting! Be nice to yourself!

	Dove.org and Common Sense Media are good references for discovering the "uplifting" level of movies [4]. kids-in-mind.com is also a good reference for profanity levels, though
sometimes it misses profanities, and it also lacks timestamps to know when the profanities occur, and doesn't allow for community contribution.  Hence this project existing.

	That being said, some videos are quite enjoyable once you strip out profanity/questionable content. It's your call.

	Enjoy your movies!

[1] http://en.wikipedia.org/wiki/Linear_video_editing
[2] http://www.mplayerhq.hu/DOCS/HTML/en/edl.html and http://en.wikipedia.org/wiki/Edit_decision_list
[3] mostly GPL programs, see http://www.gnu.org/licenses/ VLC Media Player, Mplayer/mencoder, ffmpeg, et al.
[4] http://lds.org/library/display/0,4945,161-1-11-1,00.html search for the word "wholesome"

== Installation ==

Installation and usage instructions available here: http://cleaneditingmovieplayer.inet2.org/

== Creating Your Own Edit Lists, or modifying previously existing ones ==

	Sometimes the movie you want doesn't have an EDL (edit list) available for it yet.
	Not to worry, you can create your own!
	See https://github.com/rdp/sensible-cinema/wiki/How-to-create-your-own-EDL%27s

== Feedback/Contributing to Development ==

	Feedback, including feature requests, comments, etc. are all welcome, see contact links here: http://cleaneditingmovieplayer.inet2.org

	If you're a developer and want to help out with programming or look and feel, etc., please do! See notes_for_potential_developers.txt file, and also http://github.com/rdp/sensible-cinema for source, and/or the wiki there.

	If you want to donate something, please consider donating to a charity of your choice. No really, feel free, go ahead.

== FAQ ==

Q. How do I watch these on my TV, not just on my computer?
A. One way is to plug your computer (laptop) into your TV.
  For instance, position a laptop near your TV and hook it in.  Newer TV's and laptops are typically compatible.
  Or buy a very long monitor and audio cord and plug it in from your desktop/laptop :)
  You could also buy a projector, attach your computer/laptop to it, and then use that to watch.
  If you're interested in also being able to "beam" it from your computer to your game console (ex: PS3) ping me--I might have 
  something in mind that could help, though hasn't been created yet.  (Playon.tv does something like this, too, but
  I might come up with a competitor to it if desired, as the existing one costs money).
  Another option is to purchase a clearplay DVD player.
  
Q. I want to give an edited DVD to a friend, how do I do that well?
A. Give them the original, non-edited DVD and a link to sensible-cinema's website :)

Q. Can I use this with Windows Media Center?
A. Yes, in theory you could use one of the existing WMC plugins that allows you to "call out" to a 3rd party software to play your files.
   Then use the "advanced" mode in sensible cinema "create side-by-side EDL file" button to create an EDL for your previously existing file.
   Then make your WMC plugin "call out" to smplayer to play those files (through whatever means it necessary), and
   it will automatically pick up and use the EDL file.
   You could also use the same side-by-side EDL file with XBMC, which also honors them (need at least an Eden release version).

Q. Is it ethical to watch edited movies?
  Well, producers have been making "airplane edited" movies forever... :)
  But anyway if you don't find it ethical, then do yourself a favor don't watch them.  I personally like cutting out gratuitous profanity from
  my viewing experience.
  http://en.wikipedia.org/wiki/Re-edited_film

Q. Can I know if movies in the theaters have profanity in them?
A. You can--you can download their subtitle file, then use the "part subtitle" button to tell if even movies
   *in the theater* have profanity (this won't help you skip that profanity, obviously, if you go to see it, but it's
   a heads up).  Kids-in-mind.com and common sense media reviews are helpful, as well, though sometimes they miss
   profanity words, one or two.

== Caveats ==

	NB that "someone" has to first create a edit list, per DVD.

	If one doesn't yet exist for the DVD you want edited, you could create it yourself, or employ somebody to create it.  Make sure to submit it back to us when you are done, so that the
rest of the users can benefit from it. Fortunately just one person has to do it, once, for everybody to benefit, and the editing process is not too bad.

	We also have a subtitle parser which really helps locate profanity more conveniently, so that will help you build your edit list.

	Also note that if your DVD has scratches that cause it to skip, the time signatures will be off, so we recommend to always clean your discs first!

== Motivation ==

	The initial motivation for the project was that I dislike deity profanity in movies. And really any profanity is jarring, if you are not used to it in real life, and it can put me a
bit on edge when I watch an otherwise enjoyable movie. Also sometimes producers put in certain bad scenes (ex: scenes involving nudity)  just to get a desired end rating, even if the rest of the movie is not as offensive.

	I once tried Clearplay (a "filter"ed DVD player) but (for me) it didn't cut it.  It costs money monthly (I'm too cheap to pay--and many many other people don't use it because of
this...).  Casual users no longer have the option to buy specific "filters" but are obliged to purchase a monthly subscription, so it doesn't make sense financially for many casual movie viewers. For instance, if you use Redbox every week, and then have to subscribe to Clearplay, it could triple your total cost. 

	Their filters sometimes don't cut out all undesired content (ex: Saints and Soldiers left several profanities in...which was unexpected). If your standards differ from theirs, I guess
you're out of luck.  Clearplay apparently also runs a rather  confusing subscription policy, or so I'm told [1], and their DVD players that  are a bit shaky at times [2], so I'm told.  Their DVD players aren't quite as readily accessible (read: can't buy them at Walmart), nor as cheap to buy as some others.

	Clearplay also doesn't seem to have much community collaboration/review (though you can email them feedback). They also didn't have filters for all the movies that I, at times, wanted
to watch edited (Condorman and Tron) the last time I checked...probably because they were too obscure.  Also it doesn't have filters for educational videos, etc.) 

	If there isn't a filter, you basically have to request one and then *hope* they get around to it. It might take a bit longer than you'd hope (read: years). Or it might never be made. 

	Also, some people watch movies only on computer, and they no longer seem to offer a computer player, just hardware players.  They also don't edit streamed online movies either (last
time I checked, anyway), nor offer an edited blu-ray player. I also emailed them once (2003?) to inform them I'd be making an open source equivalent, and haven't heard back, which I assume to mean implicitly they are all for it (in reality this project is more like in-home Cleanflicks than Clearplay, anyway).

	Also Clearplay isn't quite flexible enough, editing out only profanity/sex/violence et al (and based only on their own criteria).  Some users may want to, for example, skip the intro's 
to specific movies (like older movies with long songs and no content during the intro) because...they want to get to the movie faster.  Or skip commercials in some personal DVD recording.
Or use it on their home DVD's.  Clearplay does not allow for any of these.  

	Also Clearplay doesn't seem to users leave comments on their filters, to improve them, etc. Also you can't tell from Clearplay's list whether a DVD is absent because it's clean, or
because they haven't done a filter for it.

	Also sometimes certain DVD's "don't work" with Clearplay for some reason (rental versions?) [3] As a friend once said "Clearplay is a bit of a hassle to use in today's day and age. It
should either have wireless or have an ethernet port on it. I should enter my login credentials to the box. When I stick a movie in, it should go to the website and download the filter."

	Clearplay's player apparently only works for region 1 DVD's. Clearplay doesn't work for straight "movie files", for instance a download of the free movie "sintel" etc.

	Also owning a Clearplay player takes at least a marginal amount of technical expertise (fails the "grandma" test). [4]

	So overall I wanted to build my own that overcame some of these hurdles. Because at least for some people if there is any cost associated, they will not consider it, so freer might be
better.

	I also wanted to get a prototype out there of some ideas so that others can't later patent them and pretend that they were first inventors later :)

	See also the "Overly Verbose History" section in the history_and_related_works_list.txt file.

[1] http://www.amazon.com/gp/product/B002YPRW7S/ref=cm_rdp_product
 "...I agree that it is not made clear on their website that if you don't continue your membership, you can't continue 
  to use the [previously downloaded] filters"

[2] http://deseretbook.com/ClearPlay-HDMI-DVD-Player-30-Day-Trial-Membership/i/5038491
 "We bought a Clearplay player about 2 years ago. It worked great, until it just stopped working. I called their support line, 
  and they told us the model we got was defective, and that the new one was much better and we could get it at a discount, but 
  the next one just died also."

[3] http://blog.clearplay.com/2010/02/time-travelers-wife.html comments

[4] https://plus.google.com/u/0/112065817515875981770/posts/UeSPiYYTDfV

== History ==

	See the file history_and_related_works_list.txt for an overly verbose history. Also see the file change_log_with_feature_list.txt.

== Related Works ==

	See the file history_and_related_works_list.txt

== License ==

	See the included LICENSE.TXT file for licensing and usage terms (basically it's released under LGPL). Some other programs are (distributed separately and) used, if present. These are
typically released under their own copy of the gplv2 license, though some have differing licenses.

	EDL files themselves are released under the Creative Commons License, however. See first also the file "is_it_legal_to_copy_dvds.txt" for more information on legal use in your country.

== Troubleshooting ==

See the file documentation/troubleshooting.txt, or contact (see the feedback/development section).

== Thanks ==

	Thanks to Jarmo for the win32-screenshot gem, the mini_magick gem authors, jruby guys, etc. The combination of these tools made programming this actually something of a pleasure, 
and a breeze cross platform. CEM Player leverages code from lots of other projects (see LICENSE.TXT)--many thanks to the authors and maintainers of said libraries, and anybody else I forgot to mention. CEM Player also includes a conglomeration of the good ideas from several people who contacted me over time.  Thanks for your contributions.

== Competition/re-use of files ==

	Note that competition/use of files from sensible cinema is welcome!

	In fact, the current end goal is to publish the edit lists (EDL's) to a separate repository with its own API under the CC license, meaning that even "for profit" users can use them for
whatever other use they want, hopefully good uses. :)  More direct direct competitors are also welcome here.  I only made this because I had to and nothing like it existed, so if something else springs up, I'm actually happy to use it instead, too.
