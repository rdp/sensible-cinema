require "./kemal_server/*"

# module KemalServer
  # TODO Put your code here
# end

require "kemal"

get "/" do
  "Hello World! <a href=for_current>scriptz</a>"
end

get "/for_current" do |env|
  env.response.content_type = "application/javascript"
  render "src/views/html5_edited.js.ecr"
end

Kemal.run