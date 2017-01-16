require "./include/*" 

require "kemal"
require "kemal-session"
require "http/client"
require "mysql"

Session.config do |config|
  Session.config.secret = "my_super_secret"
end

before_all do |env|
  env.response.headers.add "Access-Control-Allow-Origin", "*" # so it can load JSON from other origin [amazon.com etc.]
  env.session.string("flash", "") unless env.session.string?("flash") # default
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
  render "views/html5_edited.just_settings.json.ecr"
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

get "/delete_edl/:edl_id" do |env|
  id = env.params.url["edl_id"]
  edl = Edl.get_only_by_id(id)
  edl.destroy
  save_local_javascript [edl.url], "removed #{edl}", env
  set_flash_for_next_time env, "deleted one edit"
  env.redirect "/view_url/#{edl.url.id}"
end

get "/edit_edl/:edl_id" do |env|
  edl = Edl.get_only_by_id(env.params.url["edl_id"])
  url = edl.url
  render "views/edit_edl.ecr", "views/layout.ecr"
end

def get_url_from_url_id(env)
  Url.get_only_by_id(env.params.url["url_id"])
end

get "/new_empty_edl/:url_id" do |env|
 
  url = get_url_from_url_id(env)
  edl = Edl.new url
  last_edl = url.last_edl_or_nil
  if last_edl
    # just make it slightly past the last 
    last_end = last_edl.endy
    edl.start = last_end + 1
    edl.endy = last_end + 2
  else
    # non zero anyway :|
    edl.start = 1.0
    edl.endy = 2.0
  end
  set_flash_for_next_time env, "edit is not yet saved, hit the save button when you are done"
  render "views/edit_edl.ecr", "views/layout.ecr"
end

get "/add_edl_from_plugin/:url_id" do |env|
  url = get_url_from_url_id(env)
  edl = Edl.new url
  query = env.params.query
  edl.start = url.human_to_seconds query["start"]
  edl.endy = url.human_to_seconds query["endy"]
  edl.default_action = sanitize_html query["default_action"]
  # immediate save so that I can rely on repolling this from the UI to get the ID's etc. in a few seconds after submitting it :|
  edl.category = "unknown"
  edl.subcategory = "unknown"
  edl.save
  env.redirect "/edit_edl/#{edl.id}"
end

post "/save_edl/:url_id" do |env|
  params = env.params.body
  if params["id"]?
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
  set_flash_for_next_time(env, "saved edit! reload browser if you are watching that movie in a different tab right now...")
  env.redirect "/view_url/#{url.id}"
end

get "/regenerate_all" do |env|
  # cleanse :)
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

def get_title_and_sanitized_standardized_canonical_url(real_url)
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

get "/new_url" do |env| # add_url add_new
  real_url = env.params.query["url"]
  incoming = env.params.query
  episode_number = incoming["episode_number"].to_i
  episode_name = incoming["episode_name"]
  title = incoming["title"]
  duration = incoming["duration"].to_f
  create_new_and_redir(real_url, episode_number, episode_name, title, duration, env)
end

get "/new_manual_url" do |env|
  real_url = env.params.query["url"]
  if env.params.query["episode_number"]?
    episode_number = env.params.query["episode_number"].to_i
  else
    episode_number = 0
  end
  create_new_and_redir(real_url, episode_number, "", "", 0.0, env)
end

def create_new_and_redir(real_url, episode_number, episode_name, title, duration, env)
  title_incoming, sanitized_url = get_title_and_sanitized_standardized_canonical_url real_url
  if title == ""
    title = title_incoming
  end
  url_or_nil = Url.get_only_or_nil_by_url_and_episode_number(sanitized_url, episode_number)
  if url_or_nil
    set_flash_for_next_time(env, "a movie with that description already exists, editing that instead...")
    env.redirect "/edit_url/#{url_or_nil.id}"
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
    url.total_time = duration
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
  _ , incoming_url = get_title_and_sanitized_standardized_canonical_url incoming_url # in case url changed make sure they didn't change it to a /gp/, ignore title :)
  # these get injected everywhere later so sanitize everything up front... :|
  amazon_second_url = HTML.unescape(params["amazon_second_url"])
  if amazon_second_url.present?
    _ , amazon_second_url = get_title_and_sanitized_standardized_canonical_url amazon_second_url
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
  amazon_prime_free_type = params["amazon_prime_free_type"]
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
  db_url.amazon_prime_free_type = amazon_prime_free_type
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
  env.session.string("flash", env.session.string("flash") + " " + string) # hopefully HTML strips the preceding stuff :)
end

def table_row(first_cell, second_cell)
  "<tr><td>#{first_cell}</td><td>#{second_cell}</td></tr>";
end

Kemal.run
