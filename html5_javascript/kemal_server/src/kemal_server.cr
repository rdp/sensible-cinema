require "./include//*" # one regex didn't work :|

# module KemalServer
  # TODO Put your code here
# end

require "kemal"
require "http/client"
require "sqlite3"

class Url
  DB.mapping({
    id: Int32,
    url:  String,
    name: String,
    amazon_episode_number: Int32,
  })
  
  def self.all
    with_db do |conn|
      conn.query("SELECT * from urls") do |rs|
         Url.from_rs(rs);
      end
    end
  end
  
  def self.get_single_or_nil_by_url_and_amazon_episode_number(url, amazon_episode_number)
    with_db do |conn|
      urls = conn.query("SELECT * from urls where url = ? and amazon_episode_number = ?", url, amazon_episode_number) do |rs|
         Url.from_rs(rs);
      end
      if urls.size == 1
        return urls[0]
      else
        return nil
      end
    end
  end
  
  def save
    with_db do |conn|
      if @id == 0
       @id = conn.exec("insert into urls (name, url, amazon_episode_number) values (?, ?, ?)", name, url, amazon_episode_number).last_insert_id.to_i32
      else
       conn.exec "update urls set name = ?, url = ?, amazon_episode_number = ?  where id = ?", name, url, amazon_episode_number, id
      end
    end
  end
 
  def initialize(url, name, amazon_episode_number)
    @id = 0 # :|
    @url = url
    @name = name
    @amazon_episode_number = amazon_episode_number
  end

  def initialize
    initialize("", "", 0)
  end
  
  def edls
    with_db do |conn|
      conn.query("select * from edits where url_id=? order by start desc", id) do |rs|
        Edl.from_rs rs
      end
    end
  end

  def last_edl_or_nil
    all = with_db do |conn|
      conn.query("select * from edits where url_id=? order by endy desc limit 1", id) do |rs|
        Edl.from_rs(rs)
      end
    end
    if all.size == 1
      return all[0]
    else
      return nil
    end
  end

  def destroy
    with_db do |conn|
      conn.exec("delete from urls where id = ?", id)
    end
  end

  def url_lookup_params
    "url=#{url}&amazon_episode_number=#{amazon_episode_number}"
  end

  def self.get_single_by_id(id)
    with_db do |conn|
      conn.query("SELECT * from urls where id = ?", id) do |rs|
         Url.from_rs(rs)[0] # Index OOB if not there :|
      end
    end
  end
end

class Edl
  # see edit_edl.ecr for options
  DB.mapping({
    id: Int64,
    start:   {type: Float64},
    endy: {type: Float64},
    category: {type: String},       
    subcategory: {type: String},   
    subcategory_level: Int32,   
    details: {type: String},     
    default_action: {type: String},
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
    @subcategory = ""
    @subcategory_level = 99
    @details = ""
    @default_action = "mute"
    @url_id = url.id
  end
  
  def save
    with_db do |conn|
      if @id == 0
        @id = conn.exec("insert into edits (start, endy, category, subcategory, subcategory_level, details, default_action, url_id) values (?,?,?,?,?,?,?,?)", @start, @endy, @category, @subcategory, @subcategory_level, @details, @default_action, @url_id).last_insert_id
      else
        conn.exec "update edits set start = ?, endy = ?, category = ?, subcategory = ?, subcategory_level = ?, details = ?, default_action = ? where id = ?", start, endy, category, subcategory, subcategory_level, details, default_action, id
      end
    end
  end
  
end

def seconds_to_human(ts_total)
  ts_seconds = ts_total
  hours = (ts_seconds / 3600).floor()
  ts_seconds -= hours * 3600
  minutes = (ts_seconds / 60).floor()
  ts_seconds -= minutes * 60
  # just seconds left
  if (hours > 0 || ts_total == 0) # 0 is default so show everything so they can edit it more easily
    "%01dh% 02dm %05.2fs" % [hours, minutes, ts_seconds]
  else
    "%01dm %05.2fs" % [minutes, ts_seconds]
  end
end

def human_to_seconds(ts_human)
  # ex: 01h 03m 02.52s
  sum = 0.0
  ts_human.split(/[hms ]/).reject{|separator| separator == ""}.reverse.each_with_index{|segment, idx|
    sum += segment.to_f * 60**idx
  }
  sum
end

get "/" do |env|
  env.redirect "/index"
end

def with_db
  db =  DB.open "sqlite3://./edit_descriptors/sqlite3_data.db"
  yield db ensure db.close
end
 
def real_url(env)
  unescaped = env.params.query["url"].split("?")[0] # already unescaped it on its way in, kind of them...
  # sanitize amazon which can come in multiple forms
  unescaped = unescaped.gsub("smile.amazon", "www.amazon") # :|
  if unescaped.includes?("/dp/")
    # like https://www.amazon.com/Inspired-Guns-DavidLassetter/dp/B01994W9OC/ref=sr_1_1?ie=UTF8&qid=1475369158&sr=8-1&keywords=inspired+guns
    # or https://smile.amazon.com/dp/B000GFD4C0/ref=dv_web_wtls_list_pr_28
    # we want https://www.amazon.com/gp/product/B01994W9OC in the end :|
    id = unescaped.split("/dp/")[1].split("/")[0]
    unescaped = "https://www.amazon.com/gp/product/" + id
  end
  unescaped
end

get "/for_current" do |env|
  real_url = real_url(env)
  amazon_episode_number = env.params.query["amazon_episode_number"].to_i # "always there" :)
  with_db do |conn|
    url_or_nil = Url.get_single_or_nil_by_url_and_amazon_episode_number(real_url, amazon_episode_number)
    if !url_or_nil
      "alert('none for this movie yet');"
    else
      url = url_or_nil.as(Url)
      env.response.content_type = "application/javascript" # not that this matters nor is useful since no SSL yet :|
      javascript_for(url)
    end
  end
end

def javascript_for(db_url)
  with_db do |conn|
    mute_edls = conn.query("select * from edits where url_id=? and default_action = 'mute'", db_url.id) do |rs|
      Edl.from_rs rs
    end
    skip_edls = conn.query("select * from edits where url_id=? and default_action = 'skip'", db_url.id) do |rs|
      Edl.from_rs rs
    end
    yes_audio_no_video_edls = conn.query("select * from edits where url_id=? and default_action = 'yes_audio_no_video'", db_url.id) do |rs|
      Edl.from_rs rs
    end
    yes_audio_no_videos = yes_audio_no_video_edls.map{|edl| [edl.start, edl.endy]}
    skips = skip_edls.map{|edl| [edl.start, edl.endy]}
    mutes = mute_edls.map{|edl| [edl.start, edl.endy]}
    name = URI.escape(db_url.name) # XXX this is too restrictive I believe...but this gets injected...
    url = db_url.url # HTML.escape doesn't munge : and / so this actually matches still FWIW
    render "views/html5_edited.js.ecr"
  end
end

get "/delete_url/:id" do |env|
  url = Url.get_single_by_id(env.params.url["id"])
  url.destroy
  env.redirect "/index"
end

get "/delete_edl/:id" do |env|
  id = env.params.url["id"]
  edl = Edl.get_single_by_id(id)
  edl.destroy
  save_local_javascript edl.url, "removed #{edl}"
  env.redirect "/edit?url=" + edl.url.url
end

get "/edit_edl/:id" do |env|
  edl = Edl.get_single_by_id(env.params.url["id"])
  url = edl.url
  render "views/edit_edl.ecr"
end

def get_url_from_url_id(env)
  Url.get_single_by_id(env.params.url["url_id"])
end

get "/add_edl/:url_id" do |env|
  url = get_url_from_url_id(env)
  edl = Edl.new url
  last_edl = url.last_edl_or_nil
  if last_edl
    last_end = last_edl.endy
    edl.start = last_end + 1
    edl.endy = last_end + 2
  end
  render "views/edit_edl.ecr"
end

post "/save_edl/:url_id" do |env|
  params = env.params.body
  if params.has_key? "id"
    edl = Edl.get_single_by_id(params["id"])
  else
    edl = Edl.new(get_url_from_url_id(env))
  end
  edl.start = human_to_seconds params["start"]
  edl.endy = human_to_seconds params["endy"]
  edl.default_action = sanitize_html params["default_action"] # TODO restrict somehow :|
  edl.category = sanitize_html params["category"] # hope it's a legit value LOL
  edl.subcategory = sanitize_html params["subcategory"]
  edl.subcategory_level = params["subcategory_level"].to_i
  edl.details = sanitize_html params["details"]
  raise "start is after or equal to end? please use browser back button to correct..." if (edl.start >= edl.endy)
  edl.save
  save_local_javascript edl.url, edl.inspect
  env.redirect "/edit_url/#{edl.url.id}"
end

get "/edit_url/:id" do |env| # same as "view" and "new" LOL but we have the url
  id = env.params.url["id"]
  url = Url.get_single_by_id(id)
  render "views/edit_url.ecr"
end


get "/new_url" do |env|
  real_url = real_url(env)
  if env.params.query.has_key? "amazon_episode_number"
    amazon_episode_number = env.params.query["amazon_episode_number"].to_i # if they sent one in :)
  else
    amazon_episode_number = 0
  end

  begin
    response = HTTP::Client.get real_url # download page :)
    title = response.body.scan(/<title>(.*)<\/title>/)[0][1] # hope it has one :)
    # cleanup some amazon
    title = title.gsub(": Amazon Digital Services LLC", "")
    title = title.gsub("Amazon.com: ", "")
    url = Url.new(real_url, title, amazon_episode_number)
  rescue ex
    raise "unable to download that url" + real_url + " #{ex}" # expect url to work for now :|
  end
  render "views/edit_url.ecr"
end

def sanitize_html(name)
  HTML.escape name
end

get "/index" do |env|
  urls = Url.all
  render "views/index.ecr"
end

def save_local_javascript(db_url, log_message)
  as_javascript = javascript_for(db_url)
  url_escaped = URI.escape(db_url.url)
  File.open("edit_descriptors/log.txt", "a") do |f|
    f.puts log_message
  end
  
  File.write("edit_descriptors/#{url_escaped}#{db_url.amazon_episode_number}" + ".rendered.js", "" + as_javascript)
  if !File.exists?("./this_is_development")
    system("cd edit_descriptors && git co master && git pull && git add . && git cam \"something was modified\" && git pom") # send it to gitraw...eventually :)
  end
end

post "/save_url" do |env|
  # no GET params
  params = env.params.body
  name = sanitize_html HTML.unescape(params["name"]) # unescape in case previously escaped case of re-save [otherwise it builds and builds...]
  incoming_url = sanitize_html HTML.unescape(params["url"]) # these get injected everywhere later so sanitize once up front, should be enough... :|
  amazon_episode_number = params["amazon_episode_number"].to_i

  if params.has_key? "id"
    db_url = Url.get_single_by_id(params["id"])
  else
    db_url = Url.new
  end

  db_url.url = incoming_url
  db_url.name = name
  db_url.amazon_episode_number = amazon_episode_number
  db_url.save
  save_local_javascript db_url, db_url.inspect
  env.redirect "/index"
end

Kemal.run
