require_relative 'overlayer'

class VLCProgrammer

  def self.to_english s
    @overlayer ||= OverLayer.allocate
    @overlayer.translate_time_to_human_readable s
  end

  def self.convert_to_full_xspf incoming
    out = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\" xmlns:vlc=\"http://www.videolan.org/vlc/playlist/ns/0/\">
    <title>Playlist</title>
    <!--location>c:\\installs\\test.xspf</location--> 
    <trackList>"

    mutes = incoming["mutes"] || {}
    blanks = incoming["blank_outs"] || {}
    mutes = mutes.map{|k, v| [OverLayer.translate_string_to_seconds(k), OverLayer.translate_string_to_seconds(v), :mute]}
    blanks = blanks.map{|k, v| [OverLayer.translate_string_to_seconds(k), OverLayer.translate_string_to_seconds(v), :blanks]}

    combined = (mutes+blanks).sort

    previous_end = 0
    idx = 0
    combined.each{|start, endy, type|
      # play up to here
      out += "<track>
          <title>#{to_english previous_end} to #{to_english start}</title>
          <extension application=\"http://www.videolan.org/vlc/playlist/0\">
            <vlc:id>#{idx += 1}</vlc:id>
            <vlc:option>start-time=#{previous_end}</vlc:option>
            <vlc:option>stop-time=#{start}</vlc:option>
          </extension>
          <location>dvd://e:\@1</location>
          </track>"
      # now mute
      out += "<track>
          <title>#{to_english start}s to #{to_english endy}s muted</title>
          <extension application=\"http://www.videolan.org/vlc/playlist/0\">
            <vlc:id>#{idx += 1}</vlc:id>
            <vlc:option>start-time=#{start}</vlc:option>
            <vlc:option>stop-time=#{endy}</vlc:option>
            <vlc:option>no-audio</vlc:option>
          </extension>
          <location>dvd://e:\@1</location>
          </track>"
      previous_end = endy
    }

    # now play the rest of the movie...
    out += "<track>
          <title>#{to_english previous_end} to end of film</title>
          <extension application=\"http://www.videolan.org/vlc/playlist/0\">
            <vlc:id>#{idx += 1}</vlc:id>
            <vlc:option>start-time=#{previous_end}</vlc:option>
            <vlc:option>stop-time=#{1_000_000}</vlc:option>
          </extension>
          <location>dvd://e:\@1</location>
          </track>"
    # and close the xml...
    out += "</trackList></playlist>"
  
  end

end