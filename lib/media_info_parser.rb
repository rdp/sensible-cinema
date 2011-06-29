module MediaInfoParser
  def self.parse_with_convert_command media_info, filename
    video = audio = nil
    media_info.split("Track ID").each{ |section|
      section =~ /:(\w+)(\d+)/
      id = $2
      section =~  /Stream ID:   (\w+)/ # like V_MPEG-2
      stream_type = $1
      if stream_type
        if section =~ /Frame rate/ && !video
          section =~ /Frame rate: ([\d\.]+)/
          fps = $1
          raise unless fps
          raise unless section =~ /lang: eng/ # expect...
          video = "#{stream_type}, \"#{filename}\", fps=#{fps}, track=#{id}, lang=eng"
        elsif section =~ /Channels:/ && !audio
          raise unless section =~ /lang: eng/ # hope english audio track comes first...
          # A_AC3, "G:\Video\Sintel_NTSC\title01.mkv", track=2, lang=eng
          audio = "#{stream_type}, \"#{filename}\", track=#{id}, lang=eng"
        end
      end
    }
    raise unless video && audio
    return "MUXOPT --no-pcr-on-video-pid --new-audio-pes --vbr  --vbv-len=500\n#{video}\n#{audio}"
  end
end