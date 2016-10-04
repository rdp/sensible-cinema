require "./kemal_server/*" # TODO complain name, complain one string didn't work, one regex didn't work :|

# module KemalServer
  # TODO Put your code here
# end

require "kemal"
require "http/client"
require "sqlite3"

class Url
  DB.mapping({
    id: Int32,
    url:  {type: String},
    name: {type: String},
  })
  
  def self.all
    with_db do |conn|
      conn.query("SELECT * from urls") do |rs|
         Url.from_rs(rs);
      end
    end
  end
  
  def self.get_single_or_nil_by_url(url)
    with_db do |conn|
      urls = conn.query("SELECT * from urls where url = ?", url) do |rs|
         Url.from_rs(rs);
      end
      if urls.size == 1
        return urls[0]
      else
        return Nil
      end
    end
  end
  
  def save
    with_db do |conn|
      conn.exec "update urls set name = ?, url = ? where id = ?", name, url, id
    end
  end
  
  def sanitized_url
    sanitize_html(url)
  end
  
  def sanitized_name
    sanitize_html(name)
  end
  
  def initialize(url, name)
    @id = 0 # :|
    @url = url
    @name = name
  end
  
  def edls
    with_db do |conn|
      conn.query("select * from edits where url_id=?", id) do |rs|
        Edit.from_rs rs
      end
    end
  end
  
end

class Edit
  DB.mapping({
    id: Int64,
    start:   {type: Float64},
    endy: {type: Float64},
    category: {type: String},       #  profanity or violence
    subcategory: {type: String},    #  deity or gore
    subcategory_level: Int32,       #  3 out of 10
    details: {type: String},        #  **** what is going on? said sally...
    default_action: {type: String}, #  skip, mute, almost mute, no-video-yes-audio (only skip and mute supported currently)
    url_id: Int32
  })
end

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
      unescaped = "https://www.amazon.com/gp/product/" + id
    end
  end
  env.set "real_url", unescaped
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

def with_db
  db =  DB.open "sqlite3://./db/sqlite3_data.db"
  yield db ensure db.close
end
 
def real_url(env)
  env.get("real_url").as(String)
end

get "/for_current" do |env|
  output = "";
  url = real_url(env)
  with_db do |conn|
    db_url_or_nil = Url.get_single_or_nil_by_url(url)
    if !db_url_or_nil
       env.response.status_code = 400
       # never did figure out how to write this to the output :|
       output = "unable to find one yet for #{url} <a href=\"/edit?url=#{env.get("url_escaped")}\"><br/>create new for this movie</a><br/><a href=/index>go back to index</a>" # too afraid to do straight redirect since this "should" be javascript I think...
    else
      db_url = db_url_or_nil.as(Url)
      env.response.content_type = "application/javascript" # not that this matters nor is useful since no SSL yet :|
      output = javascript_for(db_url)
    end
  end
  output
end

def javascript_for(db_url)
  with_db do |conn|
    mute_edls = conn.query("select * from edits where url_id=? and default_action = 'mute'", db_url.id) do |rs|
      Edit.from_rs rs
    end
    skip_edls = conn.query("select * from edits where url_id=? and default_action = 'skip'", db_url.id) do |rs|
      Edit.from_rs rs
    end
  
    skips = skip_edls.map{|edl| [edl.start, edl.endy]}
    mutes = mute_edls.map{|edl| [edl.start, edl.endy]}
    name = URI.escape(db_url.name) # XXX this is too restrictive I believe...but this gets injected...
    url = db_url.url
    render "src/views/html5_edited.js.ecr"
  end
end


get "/edit" do |env| # same as "view" and "new" LOL but we have the url
  url = real_url(env)
  db_url_or_nil = Url.get_single_or_nil_by_url(url)

  if db_url_or_nil
    db_url = db_url_or_nil.as(Url)
  else
    response = HTTP::Client.get env.get("real_url").as(String)
    title = response.body.scan(/<title>(.*)<\/title>/)[0][1] # hope it has one :)
    db_url = Url.new(url, title)
    # and no bound mutes yet :)
  end
  edls = db_url.edls
  render "src/views/edit.ecr"
end

def h(name) # rails style :|
  sanitize_html(name)
end

def sanitize_html(name)
  HTML.escape name
end

get "/index" do |env|
  urls_names = Url.all.map{ |url| 
    [url.url, URI.escape(url.url), sanitize_html(url.name)]
  }
  render "src/views/index.ecr"
end

post "/save" do |env|
  old_url = real_url(env)
  name = env.params.body["name"]
  url = env.params.body["url"]
  log("attempt save #{old_url} ->  #{url} as #{name}")
  db_url = Url.get_single_or_nil_by_url(old_url).as(Url)
  db_url.url = url
  db_url.name = name
  db_url.save
  
  out = javascript_for(db_url)
  url_escaped = env.get("url_escaped").as(String)
  File.write("edit_descriptors/#{url_escaped}" + ".rendered.js", "" + out) # crystal bug?
  if !File.exists?("./this_is_development")
    system("git pull && git add edit_descriptors && git cam \"edl bump\" && git pom ") # commit it to gitraw...eventually :)
  end
  "saved it<br/>#{h url}<br/><a href=/index>index</a><br/><a href=/edit?url=#{h url}>re-edit this movie</a>"
end

Kemal.run
