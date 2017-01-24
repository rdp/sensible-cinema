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

def with_db
  db_url = File.read("db/connection_string_local_box_no_commit.txt").strip
  db =  DB.open db_url
  yield db ensure db.close
end
 
def standardize_url(unescaped)
  # wait why are we doing this here *and* in javascript land? I guess its so the manual can enter here but...but...
  if unescaped =~ /amazon.com|netflix.com/
    unescaped = unescaped.split("?")[0] # strip off extra cruft and there is a lot of it LOL but google play needs to keep it
  end
  unescaped = unescaped.gsub("smile.amazon", "www.amazon") # standardize to always www for amazon
  unescaped.split("#")[0]
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

get "/nuke_test_by_url" do |env|
  real_url = env.params.query["url"]
  raise("cannot nuke non test movies, please ask us if you want to delete movie")  unless real_url.includes?("test_movie") # LOL
  sanitized_url = db_style_from_query_url(env)
  url = Url.get_only_or_nil_by_url_and_episode_number(sanitized_url, 0)
	if url
	
	  url.tag_edit_lists.each{|tag_edit_list|
		  tag_edit_list.destroy_tag_edit_list_to_tags
		  tag_edit_list.destroy_no_cascade
		}
		url.tags.each &.destroy
		url.destroy
	  set_flash_for_next_time env, "nuked testmovie from db, you can start over and do some more test editing on a blank/clean slate now"
	else
	  raise "not found?"
	end
	
end

get "/delete_url/:url_id" do |env|
  url = get_url_from_url_id(env)
  url.tags.each { |tag|
    #save_local_javascript [tag.url], "removed #{tag}", env
    #tag.destroy 
  }
  url.destroy
  set_flash_for_next_time env, "deleted movie from db " + url.url
  # could/should remove from cache :|
  env.redirect "/"
end

get "/delete_tag/:tag_id" do |env|
  id = env.params.url["tag_id"]
  tag = Tag.get_only_by_id(id)
  tag.destroy
  save_local_javascript [tag.url], "removed #{tag}", env
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
  tag.default_action = sanitize_html query["default_action"]
  # immediate save so that I can rely on repolling this from the UI to get the ID's etc. in a few seconds after submitting it :|
  tag.category = "unknown"
  tag.subcategory = "unknown"
  tag.save
  set_flash_for_next_time env, "tag saved, please fill in details about it..."
  spawn do
    save_local_javascript [url], tag.inspect, env
  end
  env.redirect "/edit_tag/#{tag.id}"
end

post "/save_tag/:url_id" do |env|
  params = env.params.body
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
  tag.default_action = sanitize_html params["default_action"] # TODO restrict more various somehow :|
  tag.category = sanitize_html params["category"]
  tag.subcategory = sanitize_html params["subcategory"]
  tag.details = sanitize_html params["details"]
  tag.more_details = sanitize_html params["more_details"]
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

get "/view_url/:url_id" do |env|
  url = get_url_from_url_id(env)
  render "views/view_url.ecr", "views/layout.ecr"
end

def download(raw_url)
  begin
    response = HTTP::Client.get raw_url
		response.body
  rescue ex
    raise "unable to download that url" + raw_url + " #{ex}" # expect url to work :|
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
  [title, sanitize_html standardize_url(real_url)] # standardize in case it is smile.amazon
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
      url.details = title[(title.index(":").as(Int32) + 1)..-1].strip # has actors after a colon...
    else
      url.name = title
    end
    url.episode_name = episode_name
    url.episode_number = episode_number
    url.editing_status = "not yet fully edited"
    url.total_time = duration
    url.save 
    set_flash_for_next_time(env, "Successfully added it to our system! Please add some information and go back and add some content tags for it!")
    env.redirect "/edit_url/#{url.id}"
  end
end

def sanitize_html(name)
  HTML.escape name
end

get "/" do |env| # index
  urls = Url.all
  render "views/index.ecr", "views/layout.ecr"
end

get "/faq" do |env|
  render "views/faq.ecr", "views/layout.ecr"
end

get "/new_tag_edit_list/:url_id" do |env|
  tag_edit_list = TagEditList.new env.params.url["url_id"].to_i
	render "views/edit_tag_edit_list.ecr", "views/layout.ecr"
end

get "/2edit_tag_edit_list/:tag_id" do |env|
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

  tag_edit_list.description = sanitize_html params["description"]
  tag_edit_list.status_notes = sanitize_html params["status_notes"]
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
		  if !File.exists?("this_is_development") # avoid restarting web server locally :|
        File.open("edit_descriptors/log.txt", "a") do |f|
          f.puts log_message + " " + db_url.name_with_episode
        end
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
  wholesome_uplifting_level = params["wholesome_uplifting_level"].to_i
  good_movie_rating = params["good_movie_rating"].to_i
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
  db_url.wholesome_uplifting_level = wholesome_uplifting_level
  db_url.good_movie_rating = good_movie_rating
  db_url.review = review
  db_url.amazon_prime_free_type = amazon_prime_free_type
  db_url.rental_cost = rental_cost
  db_url.purchase_cost = purchase_cost
  db_url.total_time = total_time
  db_url.save
	
	download_url = params["image_url"]
	if download_url.size > 0
	  # wait till now so it is guarantteed an id though this is paranoia
  	db_url.download_url download_url
    db_url.save # and don't store it as a DB key
	end
	
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

def google_search_string(url)
         google_search = URI.escape(url.name, true)
         if url.episode_number != 0
           google_search += URI.escape(" " + url.episode_number.to_s + " " + url.episode_name, true)
         end
				 google_search
end


Kemal.run
