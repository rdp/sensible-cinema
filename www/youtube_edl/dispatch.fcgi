#!/home/wilkboar/local_installs/bin/ruby
# 
require 'socket'
if Socket.gethostname =~ /bluehost.com/
  ENV['GEM_PATH'] = '/home/wilkboar/.gems:/usr/lib/ruby/gems/1.8'
  ENV['GEM_HOME'] = '/home/wilkboar/.gems'
  $: << '/home/wilkboar/ruby/gems/gems/fcgi-0.8.8/lib' # what in the world? malformed gem?
end

require "fcgi"
require 'cgi'
require 'render_edited.rb'

FCGI.each { |request|
    out = request.out
    out.print "Content-Type: text/html\n\n"
    incoming_params = CGI.parse(request.env["REQUEST_URI"].split('?')[1] || '') # assume they're like mute_starts=["33.0", "35.0"], mute_ends=["34.0", "36.0"]
    begin
      render_edited out, incoming_params
    rescue Exception => e
      out.puts "dispatch.fcgi failure [#{e}] #{e.backtrace.inspect}"
      out.puts incoming_params.inspect
    end
    request.finish
}
