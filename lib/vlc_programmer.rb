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
    blanks = blanks.map{|k, v| [OverLayer.translate_string_to_seconds(k), OverLayer.translate_string_to_seconds(v), :blank]}

    combined = (mutes+blanks).sort

    combined.each{|s, e, t|
      puts 'warning--detected an end before a start' if e < s
    }

    # a = VLCProgrammer.convert_to_full_xspf({ "mutes" => {5=> 7}, "blank_outs" => {6=>7} } )
    # should mute 5-6, skip 6-7
    combined.each_with_index{|(start, endy, type), index|
      next if index == 0 # nothing to do there..
      if type == :blank
        previous = combined[index-1]
        previous_end = previous[1]
        previous_type = previous[2]
        raise 'no overlap like that allowed as of yet' unless previous_end <= endy
        if previous_type == :mute && previous_end > start
          previous[1] = start # make it end when we start...
        end
      end
    }

    previous_end = 0
    idx = 0
    combined.each{|start, endy, type|

      next if endy <= start # ignore mutes wholly contained within blanks

      if previous_end != start
        # play up to next "questionable section"
        out += "<track>
          <title>#{to_english previous_end} to #{to_english start}</title>
          <extension application=\"http://www.videolan.org/vlc/playlist/0\">
            <vlc:id>#{idx += 1}</vlc:id>
            <vlc:option>start-time=#{previous_end}</vlc:option>
            <vlc:option>stop-time=#{start}</vlc:option>
          </extension>
          <location>dvd://e:\@1</location>
          </track>"
      end
      # now play through the muted section...
      if type == :mute
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
      end
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

# 1.8.7 compat...

class Symbol
  # Standard in ruby 1.9. See official documentation[http://ruby-doc.org/core-1.9/classes/Symbol.html]
  def <=>(with)
    return nil unless with.is_a? Symbol
    to_s <=> with.to_s
  end unless method_defined? :"<=>"
end