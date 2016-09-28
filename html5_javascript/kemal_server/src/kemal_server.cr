require "./kemal_server/*"

module KemalServer
  # TODO Put your code here
end

require "kemal"


before_all "/" do |env|
  puts "Setting response content type"
  env.response.content_type = "application/json"
end

db = ConnectionPool.new(capacity: 25, timeout: 0.01) do
  DB.open(ENV["DATABASE_URL"])
end

get "/" do
  "Hello World!"
end

Kemal.run
