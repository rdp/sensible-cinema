require "./kemal_server/*"

module KemalServer
  # TODO Put your code here
end

require "kemal"

get "/" do
  "Hello World!"
end

Kemal.run
