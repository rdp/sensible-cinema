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
    with_db do |conn|
      if @id == 0
 puts "here1"
       @id = conn.exec("insert into urls (name, url) values (?, ?)", name, url).last_insert_id.to_i32
      else
puts "here2 #{id}"
       conn.exec "update urls set name = ?, url = ? where id = ?", name, url, id
      end
    end
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
      if @id == 0
        @id = conn.exec("insert into edits (start, endy, category, subcategory, subcategory_level, details, default_action, url_id) values (?,?,?,?,?,?,?,?)", @start, @endy, @category, @subcategory, @subcategory_level, @details, @default_action, @url_id).last_insert_id
      else
        conn.exec "update edits set start = ?, endy = ?, default_action = ? where id = ?", start, endy, default_action, id
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

get "/" do
  "Hello World! Clean stream it!<br/>Offering edited netflix instant/amazon prime etc.<br/><a href=/index>index and instructions</a><br/>Email me for questions, you too can purchase this for $2, pay paypal rogerdpack@gmail.com to receive instructions."
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
  output = "";
  real_url = real_url(env)
  with_db do |conn|
    url_or_nil = Url.get_single_or_nil_by_url(real_url)
    if !url_or_nil
       env.response.status_code = 400
       sanitized_url = sanitize_html real_url
       # never did figure out how to write this to the output :|
       output = "unable to find one yet for #{sanitized_url} <a href=\"/edit?url=#{sanitized_url}\"><br/>create new for this movie</a><br/><a href=/index>go back to index</a>" # too afraid to do straight redirect since this "should" be javascript I think...
       
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

get "/delete_edl/:id" do |env|
  id = env.params.url["id"]
  edl = Edl.get_single_by_id(id)
  edl.destroy
  save_local_javascript edl.url, "removed #{edl}"
	env.redirect "/edit?url=" + edl.url.url
end

get "/edit_edl/:id" do |env|
  edl = Edl.get_single_by_id(env.params.url["id"])
  url = edl.url.url
  render "views/edit_edl.ecr"
end

get "/add_edl" do |env|
  url = real_url(env)
  edl = Edl.new(Url.get_single_by_url(url))
  render "views/edit_edl.ecr"
end

post "/save_edl" do |env|
  real_url = real_url(env)
  params = env.params.body
  if params.has_key? "id"
    edl = Edl.get_single_by_id(params["id"])
  else
    edl = Edl.new(Url.get_single_by_url(real_url))
    edl.url_id = Url.get_single_by_url(real_url).id
  end
  edl.start = human_to_seconds params["start"]
  edl.endy = human_to_seconds params["endy"]
  raise "start is after or equal to end? please use browser back button to correct..." if (edl.start >= edl.endy)
  edl.default_action = sanitize_html params["default_action"] # TODO restrict somehow :|
  edl.save
  save_local_javascript edl.url, edl.inspect
  env.redirect "/edit?url=" + edl.url.url
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
  render "views/edit.ecr"
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
  
  File.write("edit_descriptors/#{url_escaped}" + ".rendered.js", "" + as_javascript)
  if !File.exists?("./this_is_development")
    system("cd edit_descriptors && git pull && git add . && git cam \"edl was modified\" && git pom ") # commit it to gitraw...eventually :)
  end
end

post "/save" do |env|
  old_url = real_url(env)
  name = sanitize_html HTML.unescape(env.params.body["name"]) # unescape in case previously escaped case of re-save [otherwise it builds and builds...]
  incoming_url = sanitize_html HTML.unescape(env.params.body["url"]) # these get injected everywhere later so sanitize once up front, should be enough... :|
  log("attempt save #{old_url} ->  #{incoming_url} as #{name}")
  db_url = Url.get_single_or_nil_by_url(old_url)
  if db_url == Nil
    db_url = Url.new incoming_url, name
  else
    db_url = db_url.as(Url)
  end
  db_url.url = incoming_url
  db_url.name = name
  db_url.save
  save_local_javascript db_url, db_url.inspect
  "saved it<br/>#{incoming_url}<br/><a href=/index>index</a><br/><a href=/edit?url=#{incoming_url}>re-edit this movie</a>"
end

Kemal.run
