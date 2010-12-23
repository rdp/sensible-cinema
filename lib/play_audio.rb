require 'java'

class PlayAudio
  import "sun.audio.AudioStream"
  import "sun.audio.AudioPlayer"
  def self.play filename
    i = java.io.FileInputStream.new(filename)
    a = AudioStream.new(i)
    AudioPlayer.player.start(a)
  end
end

if $0 == __FILE__
 puts 'syntax: filename.wav'
 PlayAudio.play ARGV[0] # doesn't exit for awhile, for some reason
end