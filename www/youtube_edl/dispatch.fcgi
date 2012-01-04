#!/home/wilkboar/local_installs/bin/ruby
# http://rogerdpack.t28.net/sensible-cinema/youtube_edl/yo?mute_starts=10&mute_starts=30&mute_ends=20&mute_ends=35
require 'socket'
if Socket.gethostname =~ /bluehost.com/
  ENV['GEM_PATH'] = '/home/wilkboar/.gems:/usr/lib/ruby/gems/1.8'
  ENV['GEM_HOME'] = '/home/wilkboar/.gems'
  $: << '/home/wilkboar/ruby/gems/gems/fcgi-0.8.8/lib' # what in the world? malformed gem?
end

require "fcgi"
require 'cgi'
require 'erb'
template = ERB.new File.read("control_youtube.rhtml")
FCGI.each { |request|
    out = request.out
    out.print "Content-Type: text/html\n\n"
    incoming_params = CGI.parse(request.env["REQUEST_URI"].split('?')[1]) # assume they're like mute_starts=["33.0", "35.0"], mute_ends=["34.0", "36.0"]
    mutes = []
    incoming_params['mute_starts'].each_with_index{|start, idx|
      start = start.to_f
      endy = incoming_params['mute_ends'][idx].to_f
      mutes << "[#{start},#{endy}]"
      raise unless endy > start
    }
    out.puts mutes.join(',')
    out.puts template.result(binding)
    request.finish
}
