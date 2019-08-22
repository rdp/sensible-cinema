require "http/server"

server = HTTP::Server.new { }
context = OpenSSL::SSL::Context::Server.new
context.certificate_chain = "cert.pem"
context.private_key = "_key.pem"
address = server.bind_tls Socket::IPAddress.new("127.0.0.1", 8000), context
puts "listening https://127.0.0.1:8000"
server.listen
