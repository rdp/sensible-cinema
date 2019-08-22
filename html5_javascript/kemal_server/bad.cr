require "socket"
TCPSocket.open("localhost", 8081) { |socket|
  puts "connected #{socket}"
  sleep
}

