require 'java'

class PlayAudio
  import "sun.audio.AudioStream"
  import "sun.audio.AudioDataStream"
  import "sun.audio.AudioPlayer"
  import "sun.audio.ContinuousAudioDataStream"
  
  def self.play filename
    i = java.io.FileInputStream.new(filename)
    a = AudioStream.new(i)
    AudioPlayer.player.start(a)
    a
  end
  
  def self.loop filename
    i = java.io.FileInputStream.new(filename)
    a = AudioStream.new(i)
    b = a.get_data # failing means too big of data...
    c = ContinuousAudioDataStream.new(b)
    AudioPlayer.player.start(c)
    c
  end
  
  def initialize filename
    @filename = filename
  end
  
  def start
    raise if @audio_stream
    @audio_stream = PlayAudio.play @filename
  end
  
  def loop # will fail is stream > 1 MB
    raise if @audio_stream
    @audio_stream = PlayAudio.loop @filename
  end
  
  def stop
    raise unless @audio_stream
    AudioPlayer.player.stop(@audio_stream)
    @audio_stream = nil
  end
    
end

if $0 == __FILE__ # unit tests :)
 puts 'syntax: filename.wav'
 a = PlayAudio.new ARGV[0]
 a.start
 sleep 0.1
 a.stop

 a = PlayAudio.new ARGV[0]
 a.loop
 sleep 10
 a.stop
end