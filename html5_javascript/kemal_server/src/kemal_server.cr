require "./helpers/*" 

require "kemal"
require "kemal-session"
require "http/client"
require "mysql"

Session.config do |config|
  config.secret = File.read("./db/local_cookie_secret") # generate like crystal eval 'require "secure_random"; puts SecureRandom.hex(64)' > local_cookie_secret
  config.gc_interval = 30.days
  config.engine = Session::FileEngine.new({:sessions_dir => "./sessions/"}) # to survive restarts, mainly :|
  config.secure = true # secure cookies
end

before_all do |env|
  env.response.headers.add "Access-Control-Allow-Origin", "*" # so it can load JSON from other origin [amazon.com etc.] XXX do we still need this?
  env.session.string("flash", "") unless env.session.string?("flash") # set a default
end

after_all do |env|
  env.session.string("keep alive", "") # force mtime adjust until https://github.com/kemalcr/kemal-session/issues/27 fixed
end

# https://github.com/crystal-lang/crystal/issues/3997 crystal doesn't effectively call GC full whaat? 
spawn do
  loop do
    sleep 0.5
    GC.collect
  end
end

class MyDb
  @@db : DB::Database | Nil
  def self.setup # has to be in a method or weird error thrown https://github.com/crystal-lang/crystal-mysql/issues/22
    @@db ||= DB.open File.read("db/connection_string_local_box_no_commit.txt").strip
    # pool'ish...share it for now despite that feeling odd per request, as it pulls per #query one from the pool, but until they fix that *other* bug...
    # https://github.com/crystal-lang/crystal-db/issues/13 https://github.com/crystal-lang/crystal-db/issues/39 
    @@db.not_nil!
  end
end

def with_db
  yield MyDb.setup 
end
 
def standardize_url(unescaped)
  original = unescaped
  # basically do it all here, except canonicalize, which we do in javascript...
  if unescaped =~ /amazon.com|netflix.com/
    unescaped = unescaped.split("?")[0] # strip off extra cruft but google play needs to keep it https://play.google.com/store/movies/details/Ice_Age_Dawn_of_the_Dinosaurs?id=FkVpRvzYblc
  end
  unescaped = unescaped.split("&")[0] # strip off cruft https://www.youtube.com/watch?v=FzT9MS3n83U&list=PL7326EF82122776A9&index=21 :|
  unescaped = unescaped.gsub("smile.amazon", "www.amazon") # standardize to always www
  unescaped = unescaped.split("#")[0] # trailing #, die!
  puts "standardized as #{unescaped} from #{original}"
  unescaped
end

def db_style_from_query_url(env)
  real_url = env.params.query["url"] # already unescaped it on its way in, kind of them..
  sanitize_html standardize_url(real_url)
end

get "/for_current_just_settings_json" do |env|
  sanitized_url = db_style_from_query_url(env)
  episode_number = env.params.query["episode_number"].to_i # should always be present :)
  # this one looks up by URL and episode number
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

def json_for(db_url, env)
  render "views/html5_edited.just_settings.json.ecr"
end

get "/instructions" do |env|
  render "views/instructions.ecr", "views/layout.ecr"
end

get "/instructions_create_new_url" do | env|
  render "views/instructions_create_new_url.ecr", "views/layout.ecr"
end

get "/nuke_url/:url_id" do |env| # nb: never link to this to avoid crawlers accidental nukage :|
  hard_nuke_url_or_nil(get_url_from_url_id(env))
end

get "/nuke_test_by_url" do |env|
  real_url = env.params.query["url"]
  raise("cannot nuke non test movies, please ask us if you want to delete a different movie") unless real_url.includes?("test_movie") # LOL
  sanitized_url = db_style_from_query_url(env)
  url = Url.get_only_or_nil_by_url_and_episode_number(sanitized_url, 0)
  hard_nuke_url_or_nil(url)
end

def hard_nuke_url_or_nil(url)
  if url
    url.tag_edit_lists.each{|tag_edit_list|
      tag_edit_list.destroy_tag_edit_list_to_tags
      tag_edit_list.destroy_no_cascade
    }
    url.tags.each &.destroy
    url.destroy
    "nuked testmovie from db, you can start over and do some more test editing on a blank/clean slate now"
  else
   raise "not found to nuke?"
  end
end

get "/delete_url/:url_id" do |env|
  url = get_url_from_url_id(env)
  url.tags.each { |tag|
    #save_local_javascript [tag.url], "removed #{tag.inspect}", env
    #tag.destroy 
  }
  url.destroy
  set_flash_for_next_time env, "deleted movie from db " + url.url
  # could/should remove from cache :|
  env.redirect "/"
end

def logged_in?(env)
  env.session.object?("user")
end

class CustomHandler < Kemal::Handler
  def call(env)
    if env.request.path =~ /delete|nuke/ && !logged_in?(env) && !File.exists?("./this_is_development")
      set_flash_for_next_time env, "login required before you can do that..." # TODO remember where they came from to get here :|
      env.redirect "/login" 
    else
      call_next env
    end
  end
end

add_handler CustomHandler.new

get "/delete_tag/:tag_id" do |env|
  id = env.params.url["tag_id"]
  tag = Tag.get_only_by_id(id)
  tag.destroy
  save_local_javascript [tag.url], "removed #{tag.inspect}", env
  set_flash_for_next_time env, "deleted one tag"
  env.redirect "/view_url/#{tag.url.id}"
end

get "/edit_tag/:tag_id" do |env|
  tag = Tag.get_only_by_id(env.params.url["tag_id"])
  url = tag.url
  render "views/edit_tag.ecr", "views/layout.ecr"
end

def get_url_from_url_id(env)
  Url.get_only_by_id(env.params.url["url_id"])
end

get "/new_empty_tag/:url_id" do |env|
  url = get_url_from_url_id(env)
  tag = Tag.new url
  last_tag = url.last_tag_or_nil
  if last_tag
    # just make it slightly past the last 
    last_end = last_tag.endy
    tag.start = last_end + 1
    tag.endy = last_end + 2
  else
    # non zero anyway :|
    tag.start = 1.0
    tag.endy = 2.0
  end
  set_flash_for_next_time env, "tag is not yet saved, hit the save button when you are done"
  render "views/edit_tag.ecr", "views/layout.ecr"
end

get "/add_tag_from_plugin/:url_id" do |env|
  url = get_url_from_url_id(env)
  tag = Tag.new url
  query = env.params.query
  tag.start = url.human_to_seconds query["start"]
  tag.endy = url.human_to_seconds query["endy"]
  tag.default_action = resanitize_html(query["default_action"])
  # immediate save so that I can rely on repolling this from the UI to get the ID's etc. in a few seconds after submitting it :|
  tag.category = "unknown"
  tag.subcategory = "unknown"
  tag.save
  set_flash_for_next_time env, "content tag saved, please fill in details about it..."
  spawn do
    save_local_javascript [url], tag.inspect, env
  end
  env.redirect "/edit_tag/#{tag.id}"
end

post "/save_tag/:url_id" do |env|
  params = env.params.body
  puts "got params=#{params}"
  if params["id"]?
    tag = Tag.get_only_by_id(params["id"])
  else
    tag = Tag.new(get_url_from_url_id(env))
  end
  url = tag.url
  start = params["start"].strip
  endy = params["endy"].strip
  tag.start = url.human_to_seconds start
  tag.endy = url.human_to_seconds endy
  tag.default_action = resanitize_html(params["default_action"]) # TODO restrict more various somehow :|
  tag.category = resanitize_html params["category"]
  tag.subcategory = resanitize_html params["subcategory"]
  tag.details = resanitize_html params["details"]
  tag.oval_percentage_coords = resanitize_html params["oval_percentage_coords"].strip
	if tag.oval_percentage_coords.present?
	  unless (tag.oval_percentage_coords =~ /^\d+%,\d+%:\d+%,\d+%,[^\d]+$/) || (tag.oval_percentage_coords =~ /^\d+%,\d+%:\d+%,\d+%,[^\d]+--\d+%,\d+%:\d+%,\d+%,[^\d]+/ )
		  raise "bad oval coords #{tag.oval_percentage_coords} should look like 50%,50%:25%,25%,green [or that--that for oval and square]" 
		end
	end
	if tag.default_action == "black_oval_over_video" && !tag.oval_percentage_coords.present?
	  raise "black_oval_over_video requires oval_percentage_coords to be set..."
	end
  raise "start is after or equal to end? please use browser back button to correct..." if (tag.start >= tag.endy) # before_save filter LOL
  tag.save
  save_local_javascript [url], tag.inspect, env
  set_flash_for_next_time(env, "saved tag details, you can close this window now, it will have already been adopted by your playing movie...")
  env.redirect "/view_url/#{url.id}"
end

get "/edit_url/:url_id" do |env|
  url = get_url_from_url_id(env)
  render "views/edit_url.ecr", "views/layout.ecr"
end

get "/mass_upload_from_subtitle_file/:url_id" do |env|
  url = get_url_from_url_id(env)
  render "views/mass_upload_from_subtitle_file.ecr", "views/layout.ecr"
end

get "/view_url/:url_id" do |env|
  url = get_url_from_url_id(env)
  show_tag_details =  env.params.query["show_tag_details"]?
  render "views/view_url.ecr", "views/layout.ecr"
end
class AmazonUser
  JSON.mapping({
    user_id: String,
    name: String,
    email: String
  })
  include Session::StorableObject
end

get "/login_from_amazon" do |env| # amazon changes the url to this after successful auth
  out = JSON.parse download("https://api.amazon.com/auth/o2/tokeninfo?access_token=#{ env.params.query["access_token"]}")
  raise "access token does not belong to us??" unless out["aud"] == "amzn1.application-oa2-client.faf94452d819408f83ce8a93e4f46ec6"
  info = download("https://api.amazon.com/user/profile", HTTP::Headers{"Authorization" => "bearer " + env.params.query["access_token"]})
  user = AmazonUser.from_json(info)  # or JSON.parse info
  env.session.object("user", user)
  set_flash_for_next_time(env, "Successfully logged in, welcome #{user.name}!")
  env.redirect "/"
end

get "/logout" do |env|
  render "views/logout.ecr", "views/layout.ecr" # TODO just logout immediately j.s. here, but still it will then send us to logout_session
end

get "/logout_session" do |env| # j.s. sends us here...
  env.session.destroy # :| can't set flash after if I do this kemal-session #34 :|
  # set_flash_for_next_time(env, "You have been logged out.") # no personalized message for now :|
  "logged you out, click <a href=/login>here to login</a>" # amazon says to "show login page" after wait whaat?
end

def download(raw_url, headers = nil)
  begin
    response = HTTP::Client.get raw_url, headers
    response.body
  rescue ex
    raise "unable to download that url=" + raw_url + " #{ex}" # expect url to work :|
  end
end

def get_title_and_sanitized_standardized_canonical_url(real_url)
  real_url = standardize_url(real_url) # put after so the error message is friendlier :)
  downloaded = download(real_url)
  if downloaded =~ /<title[^>]*>(.*)<\/title>/i
    title = $1.strip
  else
    title = "please enter title here" # hopefully never get here :|
  end
  # startlingly, canonical from /gp/ sometimes => /gp/ yikes
  if downloaded =~ /<link rel="canonical" href="([^"]+)"/i
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
  [title, sanitize_html(real_url)]
end

class String
  def present?
    size > 0
  end
end

get "/new_url_from_plugin" do |env| # add_url add_new
  real_url = env.params.query["url"]
  incoming = env.params.query
  episode_number = incoming["episode_number"].to_i
  episode_name = incoming["episode_name"]
  title = incoming["title"]
  duration = incoming["duration"].to_f
  if real_url =~ /youtube.com/ && !real_url.includes?("?v=")
    raise "youtube nonstandard url detected, please report #{real_url}" # reject https://www.youtube.com/user/paulsoaresjr etc. which are screwy today :| though js does this too...
  end
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
  puts "using sanitized_url=#{sanitized_url} real_url=#{real_url}"
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
      # url.details = title[(title.index(":").as(Int32) + 1)..-1].strip # has actors after a colon...but feels too much like ripping their data LOL
    else
      url.name = title
    end
    url.episode_name = episode_name
    url.episode_number = episode_number
    url.editing_status = "needs review, may not yet be fully edited"
    url.total_time = duration
    url.save 
    set_flash_for_next_time(env, "Successfully added #{url.name} to our system! Please add some details, then go back and add some content tags for it!")
    download_youtube_image_if_none url
    env.redirect "/edit_url/#{url.id}"
  end
end

def sanitize_html(name)
  HTML.escape name
end

get "/" do |env| # index
  urls = Url.all
  urls.sort_by!{|url| url.url =~ /inet2.org/ ? 1 : 0} # put last
  render "views/index.ecr", "views/layout.ecr"
end

get "/privacy" do |env|
  render "views/privacy.ecr", "views/layout.ecr"
end

get "/faq" do |env|
  render "views/faq.ecr", "views/layout.ecr"
end

get "/login" do |env|
  if logged_in?(env)
    set_flash_for_next_time env, "already logged in!"
    env.redirect "/"
  else
    render "views/login.ecr", "views/layout.ecr"
  end
end

get "/new_tag_edit_list/:url_id" do |env|
  tag_edit_list = TagEditList.new env.params.url["url_id"].to_i
	render "views/edit_tag_edit_list.ecr", "views/layout.ecr"
end

get "/3delete_tag_edit_list/:tag_id" do |env|
  tag_edit_list = TagEditList.get_only_by_id env.params.url["tag_id"].to_i
	tag_edit_list.destroy_tag_edit_list_to_tags
	tag_edit_list.destroy_no_cascade
  set_flash_for_next_time env, "deleted one tag edit list"
  env.redirect "/view_url/#{tag_edit_list.url.id}"
end

get "/edit_tag_edit_list/:tag_id" do |env|
  tag_edit_list = TagEditList.get_only_by_id env.params.url["tag_id"].to_i
	render "views/edit_tag_edit_list.ecr", "views/layout.ecr"
end

post "/save_tag_edit_list" do |env| # XXXX couldn't figure out the named stuff here whaat?
  params = env.params.body # POST params
  if params["id"]?
    tag_edit_list = TagEditList.get_only_by_id params["id"]
  else
    tag_edit_list = TagEditList.new params["url_id"].to_i
  end

  tag_edit_list.description = resanitize_html params["description"]
  raise "must have name" unless tag_edit_list.description.present?
  tag_edit_list.status_notes = resanitize_html params["status_notes"]
  tag_edit_list.age_recommendation_after_edited = params["age_recommendation_after_edited"].to_i
  tag_ids = [] of Int32
  actions = [] of String
  env.params.body.each{|name, value|
  if name =~ /tag_select_(\d+)/ # hacky but you have to go down hacky either in name or value since it maps there too :|
     tag_ids << $1.to_i
    actions << value
    end
  }

  tag_edit_list.create_or_refresh(tag_ids, actions)
  set_flash_for_next_time(env, "successfully saved tag edit list #{tag_edit_list.description} if you are watching the movie in another browser window please refresh")
  save_local_javascript [tag_edit_list.url], tag_edit_list.inspect, env
  env.redirect "/view_url/#{tag_edit_list.url_id}" # back to the movie page...
end

def save_local_javascript(db_urls, log_message, env) # actually just json these days...
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
    spawn do
      system("cd edit_descriptors && git checkout master && git pull && git add . && git cam \"something was modified\" && git push origin master") # backup :|
    end
  end
end

def resanitize_html(string)
  outy = HTML.unescape(string)
  sanitize_html outy # this is HTML.escape
end

post "/save_url" do |env|
  params = env.params.body # POST params
  puts "params=#{params}"
  if params.has_key? "id"
    # these day
    db_url = Url.get_only_by_id(params["id"])
  else
    db_url = Url.new
  end
  
  # these get injected into HTML later so sanitize everything up front... :|
  name = resanitize_html(params["name"]) # unescape in case previously escaped case of re-save [otherwise it grows and grows in error...]
  incoming_url = resanitize_html(params["url"])
  if db_url.url != incoming_url
    _ , incoming_url = get_title_and_sanitized_standardized_canonical_url HTML.unescape(incoming_url) # in case url changed make sure they didn't change it to a /gp/, ignore title since it's already here manually already :|
  end
  amazon_second_url = resanitize_html(params["amazon_second_url"])
  if amazon_second_url.present?
    _ , amazon_second_url = get_title_and_sanitized_standardized_canonical_url HTML.unescape(amazon_second_url)
  end
  details = resanitize_html(params["details"])
  editing_status = resanitize_html(params["editing_status"])
  episode_number = params["episode_number"].to_i
  episode_name = resanitize_html(params["episode_name"])
  wholesome_uplifting_level = params["wholesome_uplifting_level"].to_i
  good_movie_rating = params["good_movie_rating"].to_i
  review = resanitize_html(params["review"])
  amazon_prime_free_type = resanitize_html(params["amazon_prime_free_type"])
  rental_cost = params["rental_cost"].to_f
  purchase_cost = params["purchase_cost"].to_f
  total_time = human_to_seconds params["total_time"]
  genre = resanitize_html(params["genre"])
  original_rating = resanitize_html(params["original_rating"])

  db_url.url = incoming_url
  db_url.amazon_second_url = amazon_second_url
  db_url.name = name
  db_url.details = details
  db_url.episode_number = episode_number
  db_url.episode_name = episode_name
  db_url.editing_status = editing_status
  db_url.wholesome_uplifting_level = wholesome_uplifting_level
  db_url.good_movie_rating = good_movie_rating
  db_url.review = review
  db_url.amazon_prime_free_type = amazon_prime_free_type
  db_url.rental_cost = rental_cost
  db_url.purchase_cost = purchase_cost
  db_url.total_time = total_time
  db_url.genre = genre
  db_url.original_rating = original_rating
	
  image_url = params["image_url"]

  db_url.save
  
  if image_url.present?
    db_url.download_image_url_and_save image_url
  else
    download_youtube_image_if_none db_url
  end

  save_local_javascript [db_url], db_url.inspect, env
	
  set_flash_for_next_time(env, "successfully saved #{db_url.name}")
  env.redirect "/view_url/" + db_url.id.to_s
end

def download_youtube_image_if_none(db_url)
  if !db_url.image_local_filename.present? && db_url.url =~ /youtube.com/
    # we can get an image fer free! :) The default ratio they seem to offer "wide horizon" unfortunately, though we might be able to do better XXXX
    youtube_id = db_url.url.split("?v=")[-1] # https://www.youtube.com/watch?v=9VH8lvZ-Z1g :|
    db_url.download_image_url_and_save "http://img.youtube.com/vi/#{youtube_id}/0.jpg"
  end
end

post "/upload_from_subtitles_post/:url_id" do |env|
  db_url = get_url_from_url_id(env)
  params = env.params.body # POST params
  add_to_beginning = params["add_to_beginning"].to_f
  add_to_end = params["add_to_end"].to_f
  
  if env.params.files["srt_upload"]? && env.params.files["srt_upload"].filename && env.params.files["srt_upload"].filename.not_nil!.size > 0 # kemal bug'ish :|?? also nil??
    db_url.subtitles = File.read(env.params.files["srt_upload"].tmpfile.path) # save contents, why not? :) XXX save euphemized :)
    profs, all_euphemized = SubtitleProfanityFinder.mutes_from_srt_string(db_url.subtitles)
    profs.each { |prof|
      tag = Tag.new(db_url)
      tag.start = prof[:start] - add_to_beginning
      tag.endy =  prof[:endy] + add_to_end
      tag.default_action = "mute"
      tag.category = "profanity"
      tag.subcategory = prof[:category]
      tag.details = prof[:details]
      tag.save
    }
    clean_subs = all_euphemized.reject{|p| p[:category] != nil }
    middle_sub = clean_subs[clean_subs.size / 2]
    puts "clean_subs = euphsize=#{all_euphemized.size} clean_size=#{clean_subs.size} idx=#{clean_subs.size / 2} middle_sub = #{middle_sub}"
    set_flash_for_next_time(env, "successfully uploaded subtitle file, created #{profs.size} mute tags from subtitle file. Please review them if you desire.")
    set_flash_for_next_time(env, "You should see [#{middle_sub[:details]}] at #{seconds_to_human middle_sub[:start]} if the subtitle file timing is right, please double check it using the \"frame\" button!")
  end  
  env.redirect "/view_url/" + db_url.id.to_s
end

####### view methods :)

def set_flash_for_next_time(env, string)
  if env.session.string("flash").size > 0
    env.session.string("flash", env.session.string("flash") + "<br/>" + string)
  else
    env.session.string("flash", string)
  end
end

def table_row_or_nothing(first_cell, second_cell)
  if second_cell.to_s.size > 0 && second_cell != 0
    "<tr><td>#{first_cell}</td><td>#{second_cell}</td></tr>";
  end
end

def google_search_string(url)
   google_search = URI.escape(url.name, true)
   if url.episode_number != 0
     google_search += URI.escape(" " + url.episode_number.to_s + " " + url.episode_name, true)
   end
	 google_search
end


Kemal.run
