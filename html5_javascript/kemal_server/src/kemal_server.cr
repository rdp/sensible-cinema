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
  
  def self.get_single_by_url(url)
   get_single_or_nil_by_url(url).as(Url) # class cast I guess if we're wrong here :|
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
    # TODO what if no id yet?
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
        Edl.from_rs rs
      end
    end
  end
  
end

class Edl
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
  
  def self.get_single_by_id(id)
    with_db do |conn|
      conn.query("SELECT * from edits where id = ?", id) do |rs|
         Edl.from_rs(rs)[0] # Index OOB if not there :|
      end
    end
  end
  
  def destroy
    with_db do |conn|
      conn.exec("delete from edits where id = ?", id)
    end
  end
  
  def url
    with_db do |conn|
      conn.query("select * from urls where id=?", url_id) do |rs|
        Url.from_rs(rs)[0]
      end
    end
  end
  
  def initialize(url)
    @id = 0.to_i64
    @start = 0.0
    @endy = 0.0
    @category = "profanity"
    @subcategory = "gore"
    @subcategory_level = 3
    @details = "any details"
    @default_action = "mute"
    @url_id = url.id
  end
  
  
  def save
    with_db do |conn|
      if id == 0
        puts conn.exec("insert into edits (start, endy, category, subcategory, subcategory_level, details, default_action, url_id) value (?,?,?,?,?,?,?)", @start, @endy, @category, @subcategory_level, @details, @default_action, @url_id)
        @id = conn.query_one("select last_insert_rowid()", as: Int64)
      else
        conn.exec "update edits set start = ?, endy = ? where id = ?", start, endy, @id
      end
    end
  end
  
end

def seconds_to_human(ts_seconds)
  hours = (ts_seconds / 3600).floor()
  ts_seconds -= hours * 3600
  minutes = (ts_seconds / 60).floor()
  ts_seconds -= minutes * 60
  # just seconds left
  if (hours > 0)
    "%02d:%02d:%02.2f" % [hours, minutes, ts_seconds]
  else
    "%02d:%02.2f" % [minutes, ts_seconds]
  end
end

def human_to_seconds(ts_human)
  # like 01:02:36.53
  ts = 0.0
  factor = 1
  ts_human.split(":").reverse.each {|segment|
    ts += segment.to_f + factor * 60
    factor += 1
  }
  ts
end

get "/" do
  "Hello World! Clean stream it!<br/>Offering edited netflix instant/amazon prime etc.<br/><a href=/index>index and instructions</a><br/>Email me for questions, you too can purchase this for $2, pay paypal rogerdpack@gmail.com to receive instructions."
end

def with_db
  db =  DB.open "sqlite3://./db/sqlite3_data.db"
  yield db ensure db.close
end
 
def real_url(env)
  unescaped = env.params.query["url"].split("?")[0] # already unescaped it on its way in, kind of them...
  # sanitize amazon
  unescaped = unescaped.gsub("smile.amazon", "www.amazon") # :|
  if unescaped.includes?("/dp/")
    # like https://www.amazon.com/Inspired-Guns-DavidLassetter/dp/B01994W9OC/ref=sr_1_1?ie=UTF8&qid=1475369158&sr=8-1&keywords=inspired+guns
    # we want https://www.amazon.com/gp/product/B01994W9OC
    id = unescaped.split("/")[5]
    unescaped = "https://www.amazon.com/gp/product/" + id
  end
  unescaped
end

get "/for_current" do |env|
  output = "";
  real_url = real_url(env)
  with_db do |conn|
    url_or_nil = Url.get_single_or_nil_by_url(real_url)
    if !url_or_nil
       env.response.status_code = 400
       # never did figure out how to write this to the output :|
       output = "unable to find one yet for #{h real_url} <a href=\"/edit?url=#{h real_url}\"><br/>create new for this movie</a><br/><a href=/index>go back to index</a>" # too afraid to do straight redirect since this "should" be javascript I think...
    else
      url = url_or_nil.as(Url)
      env.response.content_type = "application/javascript" # not that this matters nor is useful since no SSL yet :|
      output = javascript_for(url)
    end
  end
  output
end

def javascript_for(db_url)
  with_db do |conn|
    mute_edls = conn.query("select * from edits where url_id=? and default_action = 'mute'", db_url.id) do |rs|
      Edl.from_rs rs
    end
    skip_edls = conn.query("select * from edits where url_id=? and default_action = 'skip'", db_url.id) do |rs|
      Edl.from_rs rs
    end
  
    skips = skip_edls.map{|edl| [edl.start, edl.endy]}
    mutes = mute_edls.map{|edl| [edl.start, edl.endy]}
    name = URI.escape(db_url.name) # XXX this is too restrictive I believe...but this gets injected...
    url = db_url.url
    render "src/views/html5_edited.js.ecr"
  end
end

get "/delete_edl/:id" do |env|
  id = env.params.url["id"]
  edl = Edl.get_single_by_id(id)
  edl.destroy
  save_local_javascript edl.url
	env.redirect "/edit?url=" + edl.url.url
end

get "/edit_edl/:id" do |env|
  edl = Edl.get_single_by_id(env.params.url["id"])
  url = edl.url.url
  render "src/views/edit_edl.ecr"
end

get "/add_edl" do |env|
  url = real_url(env)
  edl = Edl.new(Url.get_single_by_url(url))
  render "src/views/edit_edl.ecr"
end

post "/save_edl" do |env|
  real_url = real_url(env)
  params = env.params.body
  puts env.params.body
  if env.params.body["id"]
    edl = Edl.get_single_by_id(params["id"])
  else
    edl = Edl.new(Url.get_single_by_url(real_url))
    edl.url_id = Url.get_single_by_url(real_url).id
  end
  edl.start = human_to_seconds params["start"]
  edl.endy = human_to_seconds params["endy"]
  
  edl.save
end

get "/edit" do |env| # same as "view" and "new" LOL but we have the url
  real_url = real_url(env)
  url_or_nil = Url.get_single_or_nil_by_url(real_url)

  if url_or_nil != Nil
    url = url_or_nil.as(Url)
  else
    begin
      response = HTTP::Client.get real_url
      title = response.body.scan(/<title>(.*)<\/title>/)[0][1] # hope it has one :)
      url = Url.new(real_url, title)
    rescue ex
      raise("unable to download that url" + real_url + " #{ex}")
    end
    # unsaved, and no bound edl's yet :)
  end
  edls = url.edls
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

def save_local_javascript(db_url)
  as_javascript = javascript_for(db_url)
  url_escaped = URI.escape(db_url.url)
  File.write("edit_descriptors/#{url_escaped}" + ".rendered.js", "" + as_javascript)
  if !File.exists?("./this_is_development")
    system("git pull && git add edit_descriptors && git cam \"edl bump\" && git pom ") # commit it to gitraw...eventually :)
  end
end

post "/save" do |env|
  old_url = real_url(env)
  name = h env.params.body["name"]
  real_url = h env.params.body["url"]
  log("attempt save #{old_url} ->  #{real_url} as #{name}")
  db_url = Url.get_single_by_url(old_url)
  db_url.url = real_url
  db_url.name = name
  db_url.save
  save_local_javascript db_url
  "saved it<br/>#{h real_url}<br/><a href=/index>index</a><br/><a href=/edit?url=#{h real_url}>re-edit this movie</a>"
end

Kemal.run