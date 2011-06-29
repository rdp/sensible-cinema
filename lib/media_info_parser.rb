module MediaInfoParser
  def self.parse_with_convert_command media_info, filename
    video = audio = nil
    media_info.split("\n\n").each{|section|
      section =~ /ID.*:.*(\d+)/
      id = $1
      section =~  /Codec ID.*: (\w+)/
      codec_type = $1
      if codec_type
        if section =~ /Video/ && !video
          raise 'bad video codec:' + codec_type unless codec_type == 'V_MPEG2'
          section =~ /([\d\.]+) fps/
          fps = $1
          raise unless fps
          raise unless section =~ /Language                         : English/
          video = "V_MPEG-2, \"#{filename}\", fps=#{fps}, track=#{id}, lang=eng"
        elsif section =~ /Audio/ && !audio
          raise unless section =~ /Language                         : English/ # hope english comes first...
          # A_AC3, "G:\Video\Sintel_NTSC\title01.mkv", track=2, lang=eng
          audio = "#{codec_type}, \"#{filename}\", track=#{id}, lang=eng"
        end
      end
    }
    raise unless video && audio
    return "--no-pcr-on-video-pid --new-audio-pes --vbr  --vbv-len=500 #{video} #{audio}"
  end
end