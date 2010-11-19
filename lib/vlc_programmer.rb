require_relative 'overlayer'
ENV['PATH'] += ";c:\program files\videolan\vlc"
class VLCProgrammer

  def self.to_english s
    @overlayer ||= OverLayer.allocate
    @overlayer.translate_time_to_human_readable s
  end

  def self.convert_to_full_xspf incoming, filename = nil, drive_with_slash = nil
    @drive = drive_with_slash || "e:\\"
    @filename = filename
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
      previous = combined[index-1]
      previous_end = previous[1]
      previous_type = previous[2]
      previous_start = previous[0]
      if type == :blank
        raise 'no overlap like that allowed as of yet' unless previous_end <= endy
        if previous_type == :mute && previous_end > start
          previous[1] = start # make it end when we start...
        end
      elsif type == :mute
        if previous_end > start
          
          if previous_end >= endy
            combined[index] = [nil] # null it out...it's a mute subsumed by a blank apparently...
            if previous_type == :mute
               raise 'overlapping mute?'
            end
          else
             # start mine when the last one ended...
             combined[index] = [previous_end, endy, type]
          end

        end
     
      else
        raise 'unexpected'
      end
    }

    out = get_header

    previous_end = 0
    idx = 0

    combined.each{|start, endy, type|
      next unless start
      next if endy <= start # ignore mutes wholly contained within blanks

      if previous_end != start
        # play up to next "questionable section"
        out += get_section("#{to_english previous_end} to #{to_english start} (clean)", previous_end, start, idx += 1)
      end
      # now play through the muted section...
      if type == :mute
        out += get_section "#{to_english start}s to #{to_english endy}s muted", start, endy, idx += 1, true
      end
      previous_end = endy
    }

    # now play the rest of the movie...
    out += get_section to_english(previous_end) + " to end of film", previous_end, 1_000_000, idx += 1
    # and close the xml...
    out += get_footer idx
  
  end
  
  def self.get_header
    if !@filename
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
      <playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\" xmlns:vlc=\"http://www.videolan.org/vlc/playlist/ns/0/\">
      <title>Playlist</title>
      <!--location>c:\\installs\\test.xspf</location--> 
      <trackList>"
    else
      ""
    end
  end
  
  def self.get_section title, start, stop, idx, no_audio = false
    loc = "dvd://#{@drive}@1"
    if !@filename
      "<track>
      <title>#{title}</title>
      <extension application=\"http://www.videolan.org/vlc/playlist/0\">
        <vlc:id>#{idx}</vlc:id>
        <vlc:option>start-time=#{start}</vlc:option>
        #{"<vlc:option>noaudio</vlc:option>" if no_audio}
        <vlc:option>stop-time=#{stop}</vlc:option>
      </extension>
      <location>#{loc}</location>
      </track>"
    else
      "call vlc -I dummy #{loc} --start-time=#{start} --stop-time=#{stop} --sout=\"file/ps:#{@filename}.ps.#{idx}\" #{"--no-sout-audio" if no_audio} vlc://quit\n" # + 
      #"call vlc #{@filename}.ps.#{idx}.tmp  --sout=file/ps:go.ps
    end
  end
  
  def self.get_footer idx
   if !@filename
    "</trackList></playlist>"
   else
    files = (1..idx).map{|n| "#{@filename}.ps.#{n}"}
    # concat
    line = 'type ' + files.join(' ')
    line += " > #{@filename}.ps\n"
    
    line += "rm " + files.join(' ') + "\n"
    line += "echo Done--you may now watch file #{@filename}.ps in VLC player"
   end
    
  end

end

# <= 1.8.7 compat...
class Symbol
  # Standard in ruby 1.9. See official documentation[http://ruby-doc.org/core-1.9/classes/Symbol.html]
  def <=>(with)
    return nil unless with.is_a? Symbol
    to_s <=> with.to_s
  end unless method_defined? :"<=>"
end