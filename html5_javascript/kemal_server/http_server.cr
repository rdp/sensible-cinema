require "http/server"

server = HTTP::Server.new do |context|
  print "."
  context.response.content_type = "text/plain"
  context.response.print "Hello world!"
end

address = server.bind_tcp 8080
puts "Listening on http://#{address}"
server.listen
