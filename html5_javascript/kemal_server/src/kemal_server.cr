require "./include/*" 

require "kemal"
require "http/client"
require "mysql"

before_all do |env|
  env.response.headers.add "Access-Control-Allow-Origin", "*" # so it can load JSON from other origin [amazon.com etc.]
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
    unescaped = unescaped.split("?")[0] # strip off extra cruft and there is a lot of it LOL but google play needs to keep it
  end
  unescaped.gsub("smile.amazon", "www.amazon") # standardize to always www
end

get "/for_current_just_settings_json" do |env|
  sanitized_url = sanitize_html standardized_param_url(env)
  episode_number = env.params.query["episode_number"].to_i # should always be present :)
  # this one looks up by URL and episode number
  with_db do |conn|
    url_or_nil = Url.get_only_or_nil_by_url_and_episode_number(sanitized_url, episode_number)
    if !url_or_nil
      env.response.status_code = 412 # avoid kemal default 404 handler :| 412 => precondition failed LOL
      "none for this movie yet #{sanitized_url} #{episode_number}" # not sure if json or javascript LOL
    else
      url = url_or_nil.as(Url)
      env.response.content_type = "application/javascript" # not that this matters nor is useful since no SSL yet :|
      json_for(url, env)
    end
  end
end

def timestamps_of_type_for_video(conn, db_url, type) 
    edls = conn.query("select * from edits where url_id=? and default_action = ?", db_url.id, type) do |rs|
      Edl.from_rs rs
    end
    edls.map{|edl| [edl.start, edl.endy]}
end

def json_for(db_url, env)
  with_db do |conn|
    request_host =  env.request.headers["Host"] # like localhost:3000
    render "views/html5_edited.just_settings.json.ecr"
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
  url.edls.each { |edl|
    save_local_javascript [edl.url], "removed #{edl}", env
    edl.destroy 
  }
  url.destroy
  set_flash_for_next_time env, "deleted movie from db"
  # could/should remove from cache :|
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
    edl.start = url.human_to_seconds query["start"]
    edl.endy = url.human_to_seconds query["endy"]
    edl.default_action = sanitize_html query["default_action"]
  else
    # a "new" EDL
    last_edl = url.last_edl_or_nil
    if last_edl
      # just make it slightly past the last 
      last_end = last_edl.endy
      edl.start = last_end + 1
      edl.endy = last_end + 2
    else
      edl.start = 0.0
      edl.endy = 1.0 # later than 0 :)
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
  url = edl.url
  start = params["start"].strip
  endy = params["endy"].strip
  edl.start = url.human_to_seconds start
  edl.endy = url.human_to_seconds endy
  edl.default_action = sanitize_html params["default_action"] # TODO restrict somehow :|
  edl.category = sanitize_html params["category"] # hope it's a legit value LOL
  edl.subcategory = sanitize_html params["subcategory"]
  edl.details = sanitize_html params["details"]
  edl.more_details = sanitize_html params["more_details"]
  raise "start is after or equal to end? please use browser back button to correct..." if (edl.start >= edl.endy) # before_save filter LOL
  edl.save
  save_local_javascript [url], edl.inspect, env
  set_flash_for_next_time(env, "saved edit! reload browser if you entered it manually...")
  env.redirect "/view_url/#{url.id}"
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

def get_title_and_sanitized_canonical_url(real_url)
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
      # but still some improvement FWIW :|
      puts "using canonical #{$1}"
      real_url = $1
    end
    if real_url.includes?("amazon.com") && real_url.includes?("/gp/") # gp is old, dp is new, we only want dp ever 
      # we should never get here now FWIW, since it converts to /dp/ with canonical above
      raise "appears you're using an amazon web page that is an old style like /gp/ if this is a new movie, please search in amazon for it again, and you should find a url like /dp/, and use that
             if it is an existing movie, enter it as the amazon_second_url instead of main url"
    end
    [title, sanitize_html standardize_url(real_url)] # standardize in case it is smile.amazon
end

class String
  def present?
    size > 0
  end
end

get "/new_url" do |env| # add_url
  real_url = standardize_url(env.params.query["url"])
  incoming = env.params.query
  episode_number = incoming["episode_number"].to_i
  episode_name = incoming["episode_name"]
  title, sanitized_url = get_title_and_sanitized_canonical_url real_url
  if incoming["title"].present?
    title = incoming["title"] # XX always just use this :|
  end
  url_or_nil = Url.get_only_or_nil_by_url_and_episode_number(sanitized_url, episode_number)
  if url_or_nil != nil
    set_flash_for_next_time(env, "a movie with that description already exists, editing that instead...")
    env.redirect "/edit_url/#{url_or_nil.as(Url).id}"
  else
    # cleanup various title crufts
    title = HTML.unescape(title) # &amp => & and there are some :|
    puts "title started as #{title}" 
    title = title.gsub("&nbsp;", " ") # HTML.unescape doesn't :|
    title = title.gsub(" | Netflix", "");
    title = title.gsub(" - Movies & TV on Google Play", "")
    title = title.gsub(": Amazon   Digital Services LLC", "")
    title = title.gsub("Amazon.com: ", "")
    title = title.gsub(" - YouTube", "")
    if sanitized_url =~ /disneymoviesanywhere/
      title = title.gsub(/^Watch /, "") # prefix :|
      title = title.gsub(" | Disney Movies Anywhere", "")
    end
    title = title.strip
    title = sanitize_html title
    puts "title ended as #{title}" # still some cruft
    url = Url.new
    url.url = sanitized_url
    if sanitized_url.includes?("amazon.com") && title.includes?(":")
      url.name = title.split(":")[0].strip
      url.details = title[(title.index(":").as(Int32) + 1)..-1].strip # has actors after a colon...
    else
      url.name = title
    end
    url.episode_name = episode_name
    url.episode_number = episode_number
    url.editing_status = "just begun editing process"
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
      as_json = json_for(db_url, env)
      escaped_url_no_slashes = URI.escape url
      File.write("edit_descriptors/#{escaped_url_no_slashes}.ep#{db_url.episode_number}" + ".html5_edited.just_settings.json.rendered.js", "" + as_json) 
   }
  }
  if !File.exists?("./this_is_development")
    system("cd edit_descriptors && git co master && git pull && git add . && git cam \"something was modified\" && git pom") # send it to rawgit...eventually :)
  end
end

post "/save_url" do |env|
  params = env.params.body # POST params
  name = sanitize_html HTML.unescape(params["name"]) # unescape in case previously escaped case of re-save [otherwise it builds and builds...]
  incoming_url = params["url"] # already unescaped I think...
  _ , incoming_url = get_title_and_sanitized_canonical_url incoming_url # in case url changed make sure they didn't change it to a /gp/, ignore title :)
  # these get injected everywhere later so sanitize everything up front... :|
  incoming_url = sanitize_html incoming_url
  amazon_second_url = HTML.unescape(params["amazon_second_url"])
  if amazon_second_url.present?
    _ , amazon_second_url = get_title_and_sanitized_canonical_url amazon_second_url
  end
  details = sanitize_html HTML.unescape(params["details"])
  editing_status = params["editing_status"]
  episode_number = params["episode_number"].to_i
  episode_name = sanitize_html HTML.unescape(params["episode_name"])
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
  db_url.episode_number = episode_number
  db_url.episode_name = episode_name
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

def set_flash_for_next_time(env, string)
  env.session["flash"] ||= ""
  env.session["flash"] = "#{env.session["flash"]}" + string # save old flash too LOL
end

def plugin_javascript(request_host)
 render("views/html5_edited.js.ecr")
end

def setup_for_chrome_extension
  localhost = plugin_javascript "localhost:3000"
  production = plugin_javascript "cleanstream.inet2.org"
  File.write("../chrome_extension/edited_generic_player.js", production)
  puts "wrote .js files, default production"
end

setup_for_chrome_extension # auto setup :)

Kemal.run
