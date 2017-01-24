require "http/client"
require "mysql"
require "json"

class Url
  DB.mapping({
    id: Int32,
    url:  String, # actually "HTML" encoded, along with everything else :)
    amazon_second_url:  String,
    name: String,
    details: String,
    episode_number: Int32,
    episode_name: String,
    editing_status: String,
    wholesome_uplifting_level: Int32,
    good_movie_rating: Int32,
    image_local_filename: String,
    review: String,
    amazon_prime_free_type: String, # "prime" "HBO"
    rental_cost: Float64,
    purchase_cost: Float64, # XXX actually Decimal [?]
    total_time: Float64,
		create_timestamp: Time
  })

  JSON.mapping({
    id: Int32,
    url:  String,
    amazon_second_url:  String,
    name: String,
    details: String,
    episode_number: Int32,
    episode_name: String,
    editing_status: String,
    wholesome_uplifting_level: Int32,
    good_movie_rating: Int32,
    image_local_filename: String,
    review: String,
    amazon_prime_free_type: String,
    rental_cost: Float64,
    purchase_cost: Float64,
    total_time: Float64,
		create_timestamp: Time
  })
  
  def self.all
    with_db do |conn|
      conn.query("SELECT * from urls order by url, amazon_prime_free_type desc") do |rs|
         Url.from_rs(rs);
      end
    end
  end

  def self.first
    with_db do |conn|
      conn.query("SELECT * from urls order by url, amazon_prime_free_type desc limit 1") do |rs|
        Url.from_rs(rs); # is there no easy "get one" option?
      end
    end[0]
  end
  
  def self.get_only_or_nil_by_url_and_episode_number(url, episode_number)
    with_db do |conn|
      urls = conn.query("SELECT * FROM urls WHERE (url = ? or amazon_second_url = ?) AND episode_number = ?", url, url, episode_number) do |rs|
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
       @id = conn.exec("insert into urls (name, url, amazon_second_url, details, episode_number, episode_name, editing_status, wholesome_uplifting_level, good_movie_rating, image_local_filename, review, amazon_prime_free_type, rental_cost, purchase_cost, total_time) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", name, url, amazon_second_url, details, episode_number, episode_name, editing_status, wholesome_uplifting_level, good_movie_rating, image_local_filename, review, amazon_prime_free_type, rental_cost, purchase_cost, total_time).last_insert_id.to_i32
			 # get create_timestamp for free by its default
      else
       conn.exec "update urls set name = ?, url = ?, amazon_second_url = ?, details = ?, episode_number = ?, episode_name = ?, editing_status = ?, wholesome_uplifting_level = ?, good_movie_rating = ?, image_local_filename = ?, review = ?, amazon_prime_free_type = ?, rental_cost = ?, purchase_cost = ?, total_time = ? where id = ?", name, url, amazon_second_url, details, episode_number, episode_name, editing_status, wholesome_uplifting_level, good_movie_rating, image_local_filename, review, amazon_prime_free_type, rental_cost, purchase_cost, total_time, id
      end
    end
  end
 
  def initialize
    @id = 0 # :|
    @url = ""
    @amazon_second_url = ""
    @name = ""
    @details = ""
    @episode_number = 0
    @episode_name = ""
    @editing_status = ""
    @wholesome_uplifting_level = 0
    @good_movie_rating = 0
    @image_local_filename = ""
    @review = ""
    @amazon_prime_free_type = ""
    @rental_cost = 0.0
    @purchase_cost = 0.0
    @total_time = 0.0
		@create_timestamp = Time.now
  end

  def tags
    with_db do |conn|
      conn.query("select * from tags where url_id=? order by start asc", id) do |rs|
        Tag.from_rs rs
      end
    end
  end
	
	def tag_edit_lists
    with_db do |conn|
      conn.query("select * from tag_edit_list where url_id=?", id) do |rs|
        TagEditList.from_rs rs
      end
    end
	end
	
	private def timestamps_of_type_for_video(conn, db_url, type) 
	  tags = conn.query("select * from tags where url_id=? and default_action = ?", db_url.id, type) do |rs|
	    Tag.from_rs rs
	  end
	  tags.map{|tag| [tag.start, tag.endy]}
	end
  
  def tags_by_type
    with_db do |conn|
      yes_audio_no_videos = timestamps_of_type_for_video conn, self, "yes_audio_no_video"
      skips = timestamps_of_type_for_video conn, self, "skip"
      mutes = timestamps_of_type_for_video conn, self, "mute"
      do_nothings = timestamps_of_type_for_video conn, self, "do_nothing"
      {yes_audio_no_videos: yes_audio_no_videos, skips: skips, mutes: mutes, do_nothings: do_nothings}  # named tuple :)
    end
  end

  def last_tag_or_nil
    all = with_db do |conn|
      conn.query("select * from tags where url_id=? order by endy desc limit 1", id) do |rs|
        Tag.from_rs(rs)
      end
    end
    if all.size == 1
      return all[0]
    else
      return nil
    end
  end

  def destroy
    # no cascade, it should do that first itself now
    with_db do |conn|
      conn.exec("delete from urls where id = ?", id)
    end
  end

  def url_lookup_params
    "url=#{URI.escape url}&episode_number=#{episode_number}" # URI.escape == escapeComponent
  end

  def human_readable_company
   # get from url host...
   check =  /\/\/([^\/]+).*/
    if url =~ check
      host = $1.split(".")[-2]
    else
      host = url # ??
    end
    if amazon_prime_free_type != ""
      if amazon_prime_free_type == "Prime"
        host +=  " prime"
      else
        host += " #{amazon_prime_free_type} prime (or purchase)"
      end
    end
    host
  end

  def seconds_to_human(ts)
    if total_time > 0 && url =~ /netflix.com/
      "-" + ::seconds_to_human(total_time - ts)
    else
      ::seconds_to_human(ts)
    end 
  end

  def human_to_seconds(ts_string)
    ts_string = ts_string.strip
    if ts_string[0] == "-"
      if total_time == 0
        raise "cannot enter negative time entry to a movie that doesn't have the 'total time' set, please set that first, then come back and save your edit again"
      end
      total_time - ::human_to_seconds(ts_string[1..-1])
    else
      ::human_to_seconds(ts_string)
    end
  end

  def cost_string
    if human_readable_company.in? ["netflix", "hulu"]
      return "subscription"
    end
    out = if rental_cost > 0 || purchase_cost > 0
       "$%.2f/$%.2f" % [rental_cost, purchase_cost]
    elsif human_readable_company == "youtube" # 0 is OK here :)
       "free (youtube)"
    else
       ""
    end
    if amazon_prime_free_type != ""
      out += " (free with #{amazon_prime_free_type})"
    end
    out
  end

  def name_with_episode
    if episode_number != 0
      local_name = name
      if local_name.size > 150
        local_name = local_name[0..150] + "..."
      end
      "#{local_name} episode #{episode_number} (#{episode_name})"
    else
      name
    end
  end
	
	def download_url(full_url)
	  image_name = File.basename(full_url).split("?")[0] # attempt get normal name :|
	  outgoing_filename = "#{id}_#{image_name}"
		@image_local_filename = outgoing_filename
	  File.write("public/movie_images/#{outgoing_filename}", download(full_url)) # guess this is OK non windows :|
	end
	
	def image_tag(size, extra_html = "")
	  if image_local_filename.present?
		  "<img src='/movie_images/#{image_local_filename}' #{size}/>#{extra_html}"
		else
		  ""
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

class Tag
  # see edit_tag.ecr for options
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
      conn.query("SELECT * from tags where id = ?", id) do |rs|
         Tag.from_rs(rs)[0] # Index OOB if not there :|
      end
    end
  end
  
  def destroy
    with_db do |conn|
      conn.exec("delete from tags where id = ?", id)
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
        @id = conn.exec("insert into tags (start, endy, category, subcategory, details, more_details, default_action, url_id) values (?,?,?,?,?,?,?,?)", @start, @endy, @category, @subcategory, @details, @more_details, @default_action, @url_id).last_insert_id.to_i32
      else
        conn.exec "update tags set start = ?, endy = ?, category = ?, subcategory = ?, details = ?, more_details = ?, default_action = ? where id = ?", start, endy, category, subcategory, details, more_details, default_action, id
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


class TagEditList
  JSON.mapping({
    id: Int32,
    url_id: Int32,
    description: {type: String},       
    status_notes: {type: String},       
    age_recommendation_after_edited: Int32
  })
  DB.mapping({
    id: Int32,
    url_id: Int32,
    description: {type: String},       
    status_notes: {type: String},       
    age_recommendation_after_edited: Int32
  })
	
	def initialize(@url_id)
    @id = 0
		@description = ""
		@status_notes = ""
		@age_recommendation_after_edited = 0
 	end

	def create_or_refresh(tag_ids, actions)
    with_db do |conn|
		  # TODO conn.exec("START TRANSACTION"); once they support it LOL
		  if (@id == 0)
			   @id = conn.exec("insert into tag_edit_list (url_id, description, status_notes, age_recommendation_after_edited) VALUES (?, ?, ?, ?)", url_id, description, status_notes, age_recommendation_after_edited).last_insert_id.to_i32
			else
			  conn.exec("update tag_edit_list set url_id = ?, description = ?, status_notes = ?, age_recommendation_after_edited = ? where id = ?", url_id, description, status_notes, age_recommendation_after_edited, id)
			end
      conn.exec("delete from tag_edit_list_to_tag where tag_edit_list_id = ?", id) # just nuke, transaction's got our back
			tag_ids.each_with_index{|tag_id, idx|
			  tag = Tag.get_only_by_id(tag_id)
				raise "tag movie mismatch #{tag_id}??" unless tag.url_id == self.url_id
			  conn.exec("insert into tag_edit_list_to_tag (tag_edit_list_id, tag_id, action) values (?, ?, ?)", self.id, tag_id, actions[idx])
			}
	  end	
	end
	
	def url
	  Url.get_only_by_id(url_id)
	end
	
	def tags_with_selected_or_not
	  all_tags = url.tags # not sure how to do this without double somethin' ... :|
    with_db do |conn|
		  all_tags.map{|tag|
			  count = conn.scalar("select count(*) from tag_edit_list_to_tag where tag_edit_list_id = ? and tag_id = ?", id, tag.id)
				if count == 1
				  action = conn.query_one("select action from tag_edit_list_to_tag where tag_edit_list_id = ? and tag_id = ?", id, tag.id, as: {String})
				  {tag, action}
				elsif count == 0
				  if self.id == 0
  				  {tag, tag.default_action}
					else
  				  {tag, "do_nothing"} # they already decided against this at some point...
					end					
				else
				  raise "double tag? #{tag}"
				end
			}
		end
	end
	
  def self.get_only_by_id(id)
    with_db do |conn|
      conn.query("SELECT * from tag_edit_list where id = ?", id) do |rs|
         TagEditList.from_rs(rs)[0] # Index OOB if not there :|
      end
    end
  end
	
  def destroy_no_cascade
    with_db do |conn|
      conn.exec("delete from tag_edit_list where id = ?", id)
    end
  end
	
	def destroy_tag_edit_list_to_tags
    with_db do |conn|
      conn.exec("delete from tag_edit_list_to_tag where tag_edit_list_id = ?", id)
    end	
	end
	

end

