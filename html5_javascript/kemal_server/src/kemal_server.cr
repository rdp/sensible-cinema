require "./kemal_server/*"

# module KemalServer
  # TODO Put your code here
# end

require "kemal"

get "/" do
  "Hello World! <a href=for_current?url_escaped=https%3A%2F%2Fwww.netflix.com%2Fwatch%2F80016224>scriptz</a>"
end

get "/for_current" do |env|

  url_unescaped = env.params.query["url_escaped"] # sad but true
  url_escaped = URI.escape url_unescaped
  log("hello #{url_escaped}")
  path = "edit_descriptors/#{url_escaped}" 
  if (!File.exists?(path) || url_escaped.includes?(".."))
    env.response.status_code = 403
    "unable to find one yet for #{path}" # never did figure out how to write this to the output :|
  else
    mutes_and_skips = File.read path
    env.response.content_type = "application/javascript"
    render "src/views/html5_edited.js.ecr"
  end
end

Kemal.run
