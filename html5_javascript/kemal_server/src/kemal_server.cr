require "./kemal_server/*"

# module KemalServer
  # TODO Put your code here
# end

require "kemal"

get "/" do
  "Hello World! Clean stream it!<br/>Offering edited netflix instant/amazon prime etc.<br/><a href=/index>index and instructions</a><br/>Email me for questions, you too can purchase this for $2, pay paypal rogerdpack@gmail.com for instructions."
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
    all_settings = File.read path
    expected_url = env.get("url_unescaped")
    env.response.content_type = "application/javascript"
    render "src/views/html5_edited.js.ecr"
  end
end

get "/edit" do |env| # same as "view" :)
  path = env.get("path").as(String)
  if File.exists?(path)
    current_text = File.read(path)
  else
    current_text = "// template [remove this line]:
var name=\"movie name\";
var fast_forwards=[[50.0, 51.0]];
var mutes=[[2.0,7.0]]; 
var skips=[[10.0, 30.0]];"
  end
  
  render "src/views/edit.ecr"
end

get "/index" do
  urls_names = Dir["edit_descriptors/*"].map{|fullish_name| 
    url = URI.unescape File.basename(fullish_name) 
    File.read(fullish_name) =~ /name="(.+)"/
    name = $1
    [url, name]
  }
  render "src/views/index.ecr"
end

post "/save" do |env|
  path = env.get("path").as(String)
  got = env.params.body["stuff"]
  log("attempt save  #{path} as #{got}")
  if got.lines.size != 3
    raise "got non 3 lines? use browser back"
  end
  got = got.gsub("\r\n", "\n")
  name = got.lines[0]
  ffs = got.lines[1]
  mutes = got.lines[2]
  skips = got.lines[3]
  if name !~ /^(var name="[^"]+";)$/
    raise "bad name? use browser back arrow"
  end
  if ffs !~ /^var fast_forwards=[\[\]\d\., ]+;$/
     raise "bad fast forwards use browser back arrow"
  end
  if mutes !~ /^var mutes=[\[\]\d\., ]+;$/
    raise "bad mutes? use browser back arrow"
  end
  if skips !~ /^var skips=[\[\]\d\., ]+;$/
    raise "bad skips? use browser back arrow"
  end
  # TODO or just allow input like a normal site rather LOL
  #if got !~ /^var name="[^"]+";\nvar mutes=[\[\]\d\., ]+;\nvar mutes=[\[\]\d\., ]+;$/m # ??
  File.write(path, got);
  "saved it<br/>#{env.get("url_unescaped")}<br>#{got.size}<br/><a href=/index>index</a><br/><a href=/edit?url=#{env.get "url_escaped"}>re-edit this movie</a>"
end

Kemal.run
