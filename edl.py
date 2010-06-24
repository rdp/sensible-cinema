#! /usr/bin/python

#
# Python ctypes bindings for VLC
# Copyright (C) 2009 the VideoLAN team
# $Id: $
#
# Authors: Olivier Aubert <olivier.aubert at liris.cnrs.fr>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
#

"""This module provides bindings for the
U{libvlc<http://wiki.videolan.org/ExternalAPI>}.

Basically I think you can pass it some funky command line thing, if you want it to save the file away
http://forum.videolan.org/viewtopic.php?f=16&t=28553&start=45

Don't worry about saving for now...maybe...hmm...


Otherwise you can monitor it...perhaps...seems already multi-threaded? VLC starts its own sub-thread, maybe, and we monitor that with ours, I guess?

what about as it skips chapters though?

It has a callback event..hmm...


Stick with Python for now--why not?

can I get the disk title in any way?...


v 0.0:

it can output some time of timestamp when you hit space. Preferably in seconds

v 0.1:

it can parse some kind of EDL file for skipping

v 0.2:

it can track progression somehow and skip forward appropriately given a single track

v 0.3:

same as above, but works for different chapters in a DVD.


wishlist:
  you give it a directory, it auto-loads on DVD based on that
  muting available
  can save it to an mp4 file somewhere, or something burnable to CD. Oh baby. CD's are cheap. DVD is ok, too.
  something of a gui
  can overlay with youtube music/video et al.
  can blank
  you can specify levels /choose levels
  """
  
if __name__ == '__main__':
    try:
        from msvcrt import getch
    except ImportError:
        def getch():
            import tty
            import termios
            fd=sys.stdin.fileno()
            old_settings=termios.tcgetattr(fd)
            try:
                tty.setraw(fd)
                ch=sys.stdin.read(1)
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
            return ch

    @callbackmethod
    def end_callback(event, data):
        print "End of stream"
        sys.exit(0)

    if sys.argv[1:]:
        instance=Instance()
        media=instance.media_new(sys.argv[1])
        player=instance.media_player_new()
        player.set_media(media)
        player.play()

        event_manager=player.event_manager()
        event_manager.event_attach(EventType.MediaPlayerEndReached, end_callback, None)

        def print_info():
            """Print information about the media."""
            #import pdb
            #pdb.set_trace()            
            media=player.get_media()
            print "State:", player.get_state()
            print "Media:", media.get_mrl()
            print "Title:", player.get_title()
            print "Chapter:", player.get_chapter()
            try:
                print "Current time:", player.get_time(), "/", media.get_duration()
                print "Position:", player.get_position() # some type of percentage
                print "FPS:", player.get_fps()
                print "Rate:", player.get_rate()
                print "Video size: (%d, %d)" % (player.video_get_size(), player.video_get_size())
            except Exception as e:
              print e
              

        def forward():
            """Go forward 1s"""
            player.set_time(player.get_time() + 1000)

        def one_frame_forward():
            """Go forward one frame"""
            player.set_time(player.get_time() + long(1000 / (player.get_fps() or 25)))

        def one_frame_backward():
            """Go backward one frame"""
            player.set_time(player.get_time() - long(1000 / (player.get_fps() or 25)))

        def backward():
            """Go backward 1s"""
            player.set_time(player.get_time() - 1000)

        def print_help():
            """Print help
            """
            print "Commands:"
            for k, m in keybindings.iteritems():
                print "  %s: %s" % (k, (m.__doc__ or m.__name__).splitlines()[0])
            print " 1-9: go to the given fraction of the movie"

        def quit_app():
            """Exit."""
            sys.exit(0)

        keybindings={
            'f': player.toggle_fullscreen,
            ' ': player.pause,
            '+': forward,
            '-': backward,
            '.': one_frame_forward,
            ',': one_frame_backward,
            '?': print_help,
            'i': print_info,
            'q': quit_app,
            }

        print "Press q to quit, ? to get help."
        while True:
            k=getch()
            o=ord(k)
            method=keybindings.get(k, None)
            if method is not None:
                method()
            elif o >= 49 and o <= 57:
                # Numeric value. Jump to a fraction of the movie.
                v=0.1*(o-48)
                player.set_position(v)
#    libvlc_event_type_name
