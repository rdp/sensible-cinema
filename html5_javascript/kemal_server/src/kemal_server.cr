require "./kemal_server/*"

# module KemalServer
  # TODO Put your code here
# end

require "kemal"

get "/" do
  "Hello World! <a href=for_current?url=https%3A%2F%2Fwww.netflix.com%2Fwatch%2F80016224>scriptz</a>i <a href=/index>index</a>"
end

def setup(env)
  env.set "url_unescaped", unescaped = env.params.query["url"] # already unescaped it on its way in...
  env.set "url_escaped", url_escaped = URI.escape(unescaped)
  env.set "path" , "edit_descriptors/#{url_escaped}" 
end

before_get "/for_current" do |env|
  setup(env)
end

before_get "/edit" do |env|
  setup(env)
end
before_post "/save" do |env|
  setup(env)
end

get "/for_current" do |env|
  path = env.get("path").as(String)
  if (!File.exists?(path) || path.includes?(".."))
    env.response.status_code = 403
    # never did figure out how to write this to the output :|
    "unable to find one yet for #{env.get("url_unescaped")} <a href=\"/edit?url=#{env.get("url_escaped")}\">create new</a>" # too afraid to do straight redirect :)
  else
    eutes_and_skips = File.read path
    env.response.content_type = "application/javascript"
    render "src/views/html5_edited.js.ecr"
  end
end

get "/edit" do |env|
  path = env.get("path").as(String)
  if File.exists?(path)
    current_text = File.read(path)
  else
    current_text = " // template:
var mutes=[[2.0,7.0]];   
var skips=[[10.0, 30.0]]"
  end
  
  render "src/views/edit.ecr"
end

get "/index" do
  names = Dir["edit_descriptors/*"].map{|fullish_name| URI.unescape File.basename(fullish_name) }
  render "src/views/index.ecr"
end

post "/save" do |env|
  path = env.get("path").as(String)
  got = env.params.body["stuff"]
  log("saving #{path} as #{got}")
  File.write(path, got);
  "saved it #{env.get("url_unescaped")} #{got}<a href=/index>index</a>"
end

Kemal.run
