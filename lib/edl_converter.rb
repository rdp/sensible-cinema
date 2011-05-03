#from: https://gist.github.com/52f5c6386fc67e9e6b6b
require 'rubygems'
require 'timecode' # from http://guerilla-di.org/timecode
require 'json'

class MplayerEdl
  attr_reader :edl

  def initialize(edl)
    @edl = edl
  end

  def to_s
    out = []
    edl['events'].each do |event|
      out << ("%0.1f\t%0.1f\t%d" % [
          event['source_in'].to_seconds,
          event['source_out'].to_seconds,
          (event['transition'] == 'cut') ? 0 : 1
        ])
    end
    out.join("\n")
  end
end

edl = JSON.load(IO.read("All Dogs Go To Heaven.json"))
edl['events'].map! do |event|
  event['source_in']  = Timecode.parse(event['source_in'],  edl['film_fps'])
  event['source_out'] = Timecode.parse(event['source_out'], edl['film_fps'])
  event
end

m = MplayerEdl.new(edl)
puts m.to_s