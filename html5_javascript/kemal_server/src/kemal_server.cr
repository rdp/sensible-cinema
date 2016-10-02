require "./kemal_server/*" # TODO complain name, complain one string didn't work, one regex didn't work :|

# module KemalServer
  # TODO Put your code here
# end

require "kemal"
require "http/client"


get "/" do
  "Hello World! Clean stream it!<br/>Offering edited netflix instant/amazon prime etc.<br/><a href=/index>index and instructions</a><br/>Email me for questions, you too can purchase this for $2, pay paypal rogerdpack@gmail.com to receive instructions."
end

def setup(env)
  unescaped = env.params.query["url"].split("?")[0] # already unescaped it on its way in, kind of them...
  if (unescaped)
    unescaped = unescaped.gsub("smile.amazon", "www.amazon") # :|
    if unescaped.includes?("/dp/")
      # like https://www.amazon.com/Inspired-Guns-DavidLassetter/dp/B01994W9OC/ref=sr_1_1?ie=UTF8&qid=1475369158&sr=8-1&keywords=inspired+guns
      # we want https://www.amazon.com/gp/product/B01994W9OC
      id = unescaped.split("/")[5]
      unescaped = " https://www.amazon.com/gp/product/" + id
    end
  end
  env.set "url_unescaped", unescaped
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
    "unable to find one yet for #{env.get("url_unescaped")} <a href=\"/edit?url=#{env.get("url_escaped")}\"><br/>create new for this movie</a><br/><a href=/index>go back to index</a>" # too afraid to do straight redirect :)
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
    response = HTTP::Client.get env.get("url_unescaped").as(String)
    title = response.body.scan(/<title>(.*)<\/title>/)[0][1] # hope it has one :)
    current_text = "// template [DELETE THIS LINE]:
var name=\"#{title}\";
var fast_forwards=[[50.0, 51.0]];
var mutes=[[2.0,7.0]]; 
var skips=[[10.0, 30.0]];"
  end
  
  render "src/views/edit.ecr"
end

get "/index" do
  urls_names = Dir["edit_descriptors/*"].reject{|file| file =~ /.rendered.js/}.map{ |fullish_name| 
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
  if got.lines.size != 4
    raise "got non 4 lines? use browser back (delete top line?)"
  end
  got = got.gsub("\r\n", "\n")
  name = got.lines[0]
  ffs = got.lines[1]
  skips = got.lines[2]
  mutes = got.lines[3]
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
  # TODO allow input like a normal site rather than raw javascript LOL
  File.write(path, got);
  all_settings = got
  expected_url = env.get("url_unescaped")
  out = (render( "src/views/html5_edited.js.ecr"))
  File.write(path + ".rendered.js", "" + out) # crystal bug?
  system("git pull && git add #{File.dirname path} && git cam \"edl bump\" && git pom ") # commit it to gitraw...kind of... ;|
  "saved it<br/>#{env.get("url_unescaped")}<br>full size=#{got.size}<br/><a href=/index>index</a><br/><a href=/edit?url=#{env.get "url_escaped"}>re-edit this movie</a>"
end

Kemal.run
