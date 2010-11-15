require_relative 'overlayer'

class VLCProgrammer

  def self.convert_to_full_xspf incoming
    out = "<?xml version=1.0 encoding=UTF-8?>
    <playlist version=1 xmlns=http://xspf.org/ns/0/ xmlns:vlc=http://www.videolan.org/vlc/playlist/ns/0/>
    <title>Playlist</title>
    <!--location>c:\installs\test.xspf</location-->

    <trackList>"
    require 'ruby-debug'
    ##debugger
    33
    mutes = incoming["mutes"] || {}
    sorted_mutes = mutes.map{|k, v| [OverLayer.translate_string_to_seconds(k), OverLayer.translate_string_to_seconds(v)]}.sort
    #blanks = incoming["blank_outs"] || {}
    # now invert them
    previous_end = 0
    idx = 0
    sorted_mutes.each{|start, endy|
      # play up to here
      out += "<track>

          <!--title>Track 1</title>
          <extension application=http://www.videolan.org/vlc/playlist/0>
          <vlc:id>#{idx += 1}</vlc:id>
          <vlc:option>start-time=#{previous_end}</vlc:option>
          <vlc:option>stop-time=#{start}</vlc:option>
          </extension>
          <location>dvd://e:\@1</location>
          </track>"
      # now mute
      out += "<track>
          <!--title>Track 1</title>
          <extension application=http://www.videolan.org/vlc/playlist/0>
          <vlc:id>#{idx += 1}</vlc:id>
          <vlc:option>start-time=#{start}</vlc:option>
          <vlc:option>stop-time=#{endy}</vlc:option>
          </extension>
          <location>dvd://e:\@1</location>
          </track>"
      previous_end = endy

    }
    # now play the rest of the movie...
    out += "<track>
          <!--title>Track 1</title>
          <extension application=”http://www.videolan.org/vlc/playlist/0″>
          <vlc:id>#{idx += 1}</vlc:id>
          <vlc:option>start-time=#{previous_end}</vlc:option>
          <vlc:option>stop-time=#{1_000_000}</vlc:option>
          </extension>
          <location>dvd://e:\@1</location>
          </track>"

    out
  
  end

end