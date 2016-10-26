require "./include/*" 

# module KemalServer
  # TODO Put your code here
# end

require "kemal"
require "http/client"
#require "sqlite3"
require "mysql"

class Url
  DB.mapping({
    id: Int32,
    url:  String,
    amazon_second_url:  String,
    name: String,
    details: String,
    amazon_episode_number: Int32,
    amazon_episode_name: String,
    editing_status: String,
    age_recommendation_after_edited: Int32,
    wholesome_uplifting_level: Int32,
    good_movie_rating: Int32,
    image_url: String,
    review: String,
    is_amazon_prime: Int32,
    rental_cost: Float64,
    purchase_cost: Float64, # XXX actually Decimal [?]
    total_time: Float64
  })

  JSON.mapping({
    id: Int32,
    url:  String,
    amazon_second_url:  String,
    name: String,
    details: String,
    amazon_episode_number: Int32,
    amazon_episode_name: String,
    editing_status: String,
    age_recommendation_after_edited: Int32,
    wholesome_uplifting_level: Int32,
    good_movie_rating: Int32,
    image_url: String,
    review: String,
    is_amazon_prime: Int32,
    rental_cost: Float64,
    purchase_cost: Float64,
    total_time: Float64
  })
  
  def self.all
    with_db do |conn|
      conn.query("SELECT * from urls order by url, is_amazon_prime desc") do |rs|
         Url.from_rs(rs);
      end
    end
  end
  
  def self.get_only_or_nil_by_url_and_amazon_episode_number(url, amazon_episode_number)
    with_db do |conn|
      urls = conn.query("SELECT * FROM urls WHERE (url = ? or amazon_second_url = ?) AND amazon_episode_number = ?", url, url, amazon_episode_number) do |rs|
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
       @id = conn.exec("insert into urls (name, url, amazon_second_url, details, amazon_episode_number, amazon_episode_name, editing_status, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, image_url, review, is_amazon_prime, rental_cost, purchase_cost, total_time) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", name, url, amazon_second_url, details, amazon_episode_number, amazon_episode_name, editing_status, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, image_url, review, is_amazon_prime, rental_cost, purchase_cost, total_time).last_insert_id.to_i32
      else
       conn.exec "update urls set name = ?, url = ?, amazon_second_url = ?, details = ?, amazon_episode_number = ?, amazon_episode_name = ?, editing_status = ?, age_recommendation_after_edited = ?, wholesome_uplifting_level = ?, good_movie_rating = ?, image_url = ?, review = ?, is_amazon_prime = ?, rental_cost = ?, purchase_cost = ?, total_time = ? where id = ?", name, url, amazon_second_url, details, amazon_episode_number, amazon_episode_name, editing_status, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, image_url, review, is_amazon_prime, rental_cost, purchase_cost, total_time, id
      end
    end
  end
 
  def initialize
    @id = 0 # :|
    @url = ""
    @amazon_second_url = ""
    @name = ""
    @details = ""
    @amazon_episode_number = 0
    @amazon_episode_name = ""
    @editing_status = ""
    @age_recommendation_after_edited = 0
    @wholesome_uplifting_level = 0
    @good_movie_rating = 0
    @image_url = ""
    @review = ""
    @is_amazon_prime = 0
    @rental_cost = 0.0
    @purchase_cost = 0.0
    @total_time = 0.0
  end

  def edls
    with_db do |conn|
      conn.query("select * from edits where url_id=? order by start asc", id) do |rs|
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

  def host_like_netflix
   check =  /\/\/([^\/]+).*/
    if url =~ check
      host = $1.split(".")[-2]
    else
      host = url # ??
    end
    if is_amazon_prime?
      host += " prime"
    end
    host
  end

  def is_amazon_prime?
    if is_amazon_prime == 0
      false
    else
      true
    end
  end

  def review_with_ellipses
    if review.size > 100
      review[0..100] + "&#8230;" # :|
    else
      review
    end
  end

  def cost_string
    if rental_cost > 0 || purchase_cost > 0
      out = "%.2f/%.2f" % [rental_cost, purchase_cost]
      if is_amazon_prime == 1
        out += " (free on prime)"
      end
      out
     else
      ""
     end
  end

  def name_with_episode
    if amazon_episode_number != 0
      local_name = name
      if local_name.size > 150
        local_name = local_name[0..150] + "..."
      end
      "#{local_name} episode #{amazon_episode_number} (#{amazon_episode_name})"
    else
      name
    end
  end

  def self.get_only_by_id(id)
    with_db do |conn|
      conn.query("SELECT * from urls where id = ?", id) do |rs|
         Url.from_rs(rs)[0] # Index OOB if not there :|
      end
    end
  end
end

class Edl
  # see edit_edl.ecr for options
  JSON.mapping({
    id: Int32,
    start:   {type: Float64},
    endy: {type: Float64},
    category: {type: String},       
    subcategory: {type: String},   
    details: {type: String},     
    more_details: {type: String},     
    default_action: {type: String},
    url_id: Int32
  })
  DB.mapping({
    id: Int32,
    start:   {type: Float64},
    endy: {type: Float64},
    category: {type: String},       
    subcategory: {type: String},   
    details: {type: String},     
    more_details: {type: String},     
    default_action: {type: String},
    url_id: Int32
  })
  
  def self.get_only_by_id(id)
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
    @id = 0
    @start = 0.0
    @endy = 0.0
    @category = ""
    @subcategory = ""
    @details = ""
    @more_details = ""
    @default_action = "mute"
    @url_id = url.id
  end
  
  def save
    with_db do |conn|
      if @id == 0
        @id = conn.exec("insert into edits (start, endy, category, subcategory, details, more_details, default_action, url_id) values (?,?,?,?,?,?,?,?)", @start, @endy, @category, @subcategory, @details, @more_details, @default_action, @url_id).last_insert_id.to_i32
      else
        conn.exec "update edits set start = ?, endy = ?, category = ?, subcategory = ?, details = ?, more_details = ?, default_action = ? where id = ?", start, endy, category, subcategory, details, more_details, default_action, id
      end
    end
  end
  
end

def seconds_to_human(ts, url)
  if (url.total_time > 0 && url.url =~ /netflix.com/)
    # negative for easier entry :)
    "-" + seconds_to_human(url.total_time - ts)
  else
    seconds_to_human(ts)
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
  db_url = File.read("db/connection_string_local_box_no_commit.txt").strip
  db =  DB.open db_url
  yield db ensure db.close
end
 
def standardized_param_url(env)
  unescaped = env.params.query["url"] # already unescaped it on its way in, kind of them..
  standardize_url unescaped
end

def standardize_url(unescaped)
  if unescaped =~ /amazon.com|netflix.com/
    unescaped = unescaped.split("?")[0] # strip off extra cruft and there is a lot of it LOL but google play needs it
  end
  unescaped = unescaped.gsub("smile.amazon", "www.amazon") # standardize to always www
  # canonical is like https://www.amazon.com/Avatar-Last-Airbender-Season-3/dp/B001J6GZXK try and use that for now :|
  unescaped
end

get "/for_current_just_settings" do |env|
  get_for_current(env, "html5_edited.just_settings.js")
end

get "/for_current_just_settings_json" do |env|
  get_for_current(env, "html5_edited.just_settings.json")
end

get "/for_current" do |env|
  get_for_current(env, "html5_edited.js")
end

def get_for_current(env, type)
  standardized_param_url = standardized_param_url(env)
  amazon_episode_number = env.params.query["amazon_episode_number"].to_i # "always there" :)
  # this one looks up by URL and episode number
  with_db do |conn|
    url_or_nil = Url.get_only_or_nil_by_url_and_amazon_episode_number(standardized_param_url, amazon_episode_number)
    if !url_or_nil
      "alert('none for this movie yet');" # no 404 might be useful here :|
    else
      url = url_or_nil.as(Url)
      env.response.content_type = "application/javascript" # not that this matters nor is useful since no SSL yet :|
      javascript_for(url, env, type)
    end
  end
end

def timestamps_of_type_for_video(conn, db_url, type) 
    edls = conn.query("select * from edits where url_id=? and default_action = ?", db_url.id, type) do |rs|
      Edl.from_rs rs
    end
    edls.map{|edl| [edl.start, edl.endy]}
end

def javascript_for(db_url, env, type)
  with_db do |conn|
    yes_audio_no_videos = timestamps_of_type_for_video conn, db_url, "yes_audio_no_video"
    skips = timestamps_of_type_for_video conn, db_url, "skip"
    mutes = timestamps_of_type_for_video conn, db_url, "mute"
    do_nothings = timestamps_of_type_for_video conn, db_url, "do_nothing"
    
    name = db_url.name
    episode_name = URI.escape(db_url.amazon_episode_name) 
    url = db_url.url # HTML.escape doesn't munge : and / so this actually matches still FWIW
    request_host =  env.request.headers["Host"] # like localhost:3000
    if type == "html5_edited.js"
      render "views/html5_edited.js.ecr"
    elsif type == "html5_edited.just_settings.json"
      render "views/html5_edited.just_settings.json.ecr"
    else
      raise "wrong type" + type if type != "html5_edited.just_settings.js"
      render "views/html5_edited.just_settings.js.ecr"
    end
  end
end

get "/instructions" do |env|
  render "views/instructions.ecr", "views/layout.ecr"
end

get "/create_new" do | env|
  render "views/create_new.ecr", "views/layout.ecr"
end

get "/delete_url/:url_id" do |env|
  url = get_url_from_url_id(env)
  url.destroy
  env.redirect "/index"
end

get "/delete_edl/:id" do |env|
  id = env.params.url["id"]
  edl = Edl.get_only_by_id(id)
  edl.destroy
  save_local_javascript [edl.url], "removed #{edl}", env
  set_flash_for_next_time env, "deleted one edit"
  env.redirect "/view_url/#{edl.url.id}"
end

get "/edit_edl/:id" do |env|
  edl = Edl.get_only_by_id(env.params.url["id"])
  url = edl.url
  render "views/edit_edl.ecr", "views/layout.ecr"
end

def get_url_from_url_id(env)
  Url.get_only_by_id(env.params.url["url_id"])
end

get "/add_edl/:url_id" do |env|
  url = get_url_from_url_id(env)
  edl = Edl.new url
  query = env.params.query
  if query.has_key?("start")
    edl.start = human_to_seconds query["start"]
    edl.endy = human_to_seconds query["endy"]
    edl.default_action = sanitize_html query["default_action"]
  else
    # just make it past the last instead of 0's XXX remove?
    last_edl = url.last_edl_or_nil
    if last_edl
      last_end = last_edl.endy
      edl.start = last_end + 1
      edl.endy = last_end + 2
    end
  end
  render "views/edit_edl.ecr", "views/layout.ecr"
end

post "/save_edl/:url_id" do |env|
  params = env.params.body
  if params.has_key? "id"
    edl = Edl.get_only_by_id(params["id"])
  else
    edl = Edl.new(get_url_from_url_id(env))
  end
  edl.start = human_to_seconds params["start"]
  edl.endy = human_to_seconds params["endy"]
  edl.default_action = sanitize_html params["default_action"] # TODO restrict somehow :|
  edl.category = sanitize_html params["category"] # hope it's a legit value LOL
  edl.subcategory = sanitize_html params["subcategory"]
  edl.details = sanitize_html params["details"]
  edl.more_details = sanitize_html params["more_details"]
  raise "start is after or equal to end? please use browser back button to correct..." if (edl.start >= edl.endy) # before_save filter LOL
  edl.save
  save_local_javascript [edl.url], edl.inspect, env
  set_flash_for_next_time(env, "saved edit!")
  env.redirect "/view_url/#{edl.url.id}"
end

get "/regenerate_all" do |env|
  # cleanse all :)
  Dir["edit_descriptors/*.js"].each{|file|
    File.delete file
  }
  save_local_javascript Url.all, "regen_all called", env
  set_flash_for_next_time(env, "regenerated for all...")
  env.redirect "/index"
end

get "/edit_url/:url_id" do |env|
  url = get_url_from_url_id(env)
  render "views/edit_url.ecr", "views/layout.ecr"
end

get "/view_url/:url_id" do |env|
  url = get_url_from_url_id(env)
  render "views/view_url.ecr", "views/layout.ecr"
end

def get_title_and_canonical_url(real_url)
    begin
      response = HTTP::Client.get real_url # download that page :)
    rescue ex
      raise "unable to download that url" + real_url + " #{ex}" # expect url to work :|
    end
    real_url = standardize_url(real_url) # put after so the error message is friendlier :)
    if response.body =~ /<title[^>]*>(.*)<\/title>/i
      title = $1.strip
    else
      title = "please enter title here" # hopefully never get here :|
    end
    # startlingly, canonical from /gp/ sometimes => /gp/ yikes
    if response.body =~ /<link rel="canonical" href="([^"]+)"/i
      # https://smile.amazon.com/gp/product/B001J6Y03C did canonical to https://smile.amazon.com/Avatar-Last-Airbender-Season-3/dp/B0190R77GS
      # however https://smile.amazon.com/gp/product/B001J6GZXK -> /dp/B001J6GZXK gah! 
      puts "using canonical #{$1}"
      real_url = $1
    end
    if real_url.includes?("amazon.com") && real_url.includes?("/gp/") # gp is old, dp is new, we only want dp ever 
      # TODO the url request should use canonical [!]
      # we should never get here now FWIW
      raise "appears you're using an amazon web page that is an old style like /gp/ if this is a new movie, please search in amazon for it again, and you should find a url like /dp/, and use that
             if it is an existing movie, enter it as the amazon_second_url instead of main url"
    end
    [title, standardize_url(real_url)] # standardize in case it is smile.amazon
end

get "/new_url" do |env|
  real_url = standardize_url(env.params.query["url"]) # might be an amazon url that has canonical so skip /gp/ check 
  if env.params.query.has_key? "amazon_episode_number"
    amazon_episode_number = env.params.query["amazon_episode_number"].to_i # if they sent one in :)
  else
    amazon_episode_number = 0
  end
  title, real_url = get_title_and_canonical_url real_url  
  url_or_nil = Url.get_only_or_nil_by_url_and_amazon_episode_number(real_url, amazon_episode_number)
  if url_or_nil != nil
    set_flash_for_next_time(env, "a movie with that description already exists, editing that instead...")
    env.redirect "/edit_url/#{url_or_nil.as(Url).id}"
  else
    sanitized_url = sanitize_html real_url
    title = sanitize_html title
    # cleanup title cruft
    title = title.gsub(" | Netflix", "");
    title = title.gsub(" - Movies &amp; TV on Google Play", "")
    title = title.gsub(": Amazon   Digital Services LLC", "")
    title = title.gsub("Amazon.com: ", "")
    title = title.gsub(" - YouTube", "")
    url = Url.new
    url.url = sanitized_url
    if title.includes?(":") && real_url.includes?("amazon.com")
      url.name = title.split(":")[0].strip
      url.details = title[(title.index(":").as(Int32) + 1)..-1].strip # I think it has actors after a colon...
    else
      url.name = title
    end
    url.amazon_episode_number = amazon_episode_number
    url.save 
    env.redirect "/edit_url/#{url.id}"
  end
end

def sanitize_html(name)
  HTML.escape name
end

get "/index" do |env|
  urls = Url.all
  render "views/index.ecr", "views/layout.ecr"
end

def save_local_javascript(db_urls, log_message, env)
  db_urls.each { |db_url|
    [db_url.url, db_url.amazon_second_url].reject(&.empty?).each{ |url|
      File.open("edit_descriptors/log.txt", "a") do |f|
        f.puts log_message + " " + db_url.name_with_episode
      end
      ["html5_edited.just_settings.js", "html5_edited.js", "html5_edited.just_settings.json"].each  do |type|
        as_javascript = javascript_for(db_url, env, type)
        escaped_url_no_slashes = URI.escape url
        File.write("edit_descriptors/#{escaped_url_no_slashes}.ep#{db_url.amazon_episode_number}" + ".#{type}.rendered.js", "" + as_javascript) # TODO
      end
   }
  }
  if !File.exists?("./this_is_development")
    system("cd edit_descriptors && git co master && git pull && git add . && git cam \"something was modified\" && git pom") # send it to rawgit...eventually :)
  end
end

post "/save_url" do |env|
  params = env.params.body # POST params
  name = sanitize_html HTML.unescape(params["name"]) # unescape in case previously escaped case of re-save [otherwise it builds and builds...]
  incoming_url = HTML.unescape(params["url"])
  _ , incoming_url = get_title_and_canonical_url incoming_url # in case url changed make sure they didn't change it to a /gp/, ignore title :)
  # these get injected everywhere later so sanitize everything up front... :|
  incoming_url = sanitize_html incoming_url
  amazon_second_url = HTML.unescape(params["amazon_second_url"])
  _ , amazon_second_url = get_title_and_canonical_url amazon_second_url
  amazon_second_url = sanitize_html amazon_second_url
  details = sanitize_html HTML.unescape(params["details"])
  editing_status = params["editing_status"]
  amazon_episode_number = params["amazon_episode_number"].to_i
  amazon_episode_name = sanitize_html HTML.unescape(params["amazon_episode_name"])
  age_recommendation_after_edited = params["age_recommendation_after_edited"].to_i
  wholesome_uplifting_level = params["wholesome_uplifting_level"].to_i
  good_movie_rating = params["good_movie_rating"].to_i
  image_url = sanitize_html HTML.unescape(params["image_url"])
  review = params["review"]
  is_amazon_prime = params["is_amazon_prime"].to_i
  rental_cost = params["rental_cost"].to_f
  purchase_cost = params["purchase_cost"].to_f
  total_time = human_to_seconds params["total_time"]

  if params.has_key? "id"
    # these day
    db_url = Url.get_only_by_id(params["id"])
  else
    db_url = Url.new
  end

  db_url.url = incoming_url
  db_url.amazon_second_url = amazon_second_url
  db_url.name = name
  db_url.details = details
  db_url.amazon_episode_number = amazon_episode_number
  db_url.amazon_episode_name = amazon_episode_name
  db_url.editing_status = editing_status
  db_url.age_recommendation_after_edited = age_recommendation_after_edited
  db_url.wholesome_uplifting_level = wholesome_uplifting_level
  db_url.good_movie_rating = good_movie_rating
  db_url.review = review
  db_url.image_url = image_url
  db_url.is_amazon_prime = is_amazon_prime
  db_url.rental_cost = rental_cost
  db_url.purchase_cost = purchase_cost
  db_url.total_time = total_time
  db_url.save
  save_local_javascript [db_url], db_url.inspect, env
  set_flash_for_next_time(env, "successfully saved #{db_url.name}")
  env.redirect "/view_url/" + db_url.id.to_s
end

####### view methods :)

def get_any_flash_as_box(env)
  if env.session["flash"]?
    out = "<p class=\"bg-info\">#{env.session["flash"]}</p>"
    env.session.delete "flash"
    out
  else
    ""
  end
end

def set_flash_for_next_time(env, string)
  env.session["flash"] ||= ""
  env.session["flash"] = "#{env.session["flash"]}" + string # save old flash too LOL
end

Kemal.run


