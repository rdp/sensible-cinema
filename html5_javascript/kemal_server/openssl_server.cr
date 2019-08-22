require "socket"
require "openssl"

spawn do
  loop do
    sleep 0.5
    puts "ping"
  end
end


tcp_server = TCPServer.new(8081)

ssl_context = OpenSSL::SSL::Context::Server.new
ssl_context.certificate_chain = "cert.pem"
ssl_context.private_key = "_key.pem"
ssl_server = OpenSSL::SSL::Server.new(tcp_server, ssl_context)

puts "SSL Server listening on #{tcp_server.local_address}"
while true
  begin
    puts "accepting"
    connection = ssl_server.accept
    puts "accept worked"
    begin
      connection.puts "secure message"
      print "."
#      GC.collect
    ensure
      begin
       connection.close
      rescue ex
       print "y" , ex.inspect_with_backtrace
      end
    end
  rescue e
    print "x",  e.inspect_with_backtrace
  end
end
