require "socket"

server = TCPServer.new("localhost", 1234)
puts "listening http://localhost:1234"
loop do
  begin
   server.accept do |client|
    client.puts "unsecure message"
    print "."
   end
  rescue ex
    print "x"
  end
end
