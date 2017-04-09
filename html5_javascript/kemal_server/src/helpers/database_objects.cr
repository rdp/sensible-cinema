require "http/client"
require "mysql"
require "json"
require "file_utils"

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
    wholesome_review: String,
    count_downloads: Int32,
    amazon_prime_free_type: String, # "prime" 
    rental_cost: Float64,
    purchase_cost: Float64, # XXX actually Decimal [?]
    total_time: Float64,
		create_timestamp: Time,
		subtitles: String,
    genre: String,
    original_rating: String,
    editing_notes: String,
    community_contrib: Bool
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
    wholesome_review: String,
    count_downloads: Int32,
    amazon_prime_free_type: String,
    rental_cost: Float64,
    purchase_cost: Float64,
    total_time: Float64,
		create_timestamp: Time,
    subtitles: String,
    genre: String,
    original_rating: String,
    editing_notes: String,
    community_contrib: Bool
  })

  def self.count
    with_db do |conn|
      conn.scalar "select count(*) from urls"
    end
  end
  
  def self.all
    with_db do |conn|
      # sort by host, amazon type, name for series together
      conn.query("SELECT * from urls order by SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(url, '&#x2F;', 3), ':&#x2F;&#x2F;', -1), '&#x2F;', 1), '?', 1), amazon_prime_free_type desc, name, episode_number") do |rs|
         Url.from_rs(rs);
      end
    end
  end

  def self.latest
    with_db do |conn|
      conn.query("SELECT * from urls ORDER BY create_timestamp desc limit 1") do |rs|
        Url.from_rs(rs)[0]; # is there no easy "get one" option?
      end
    end
  end

  def self.random
    with_db do |conn|
      conn.query("SELECT * from urls ORDER BY rand() limit 1") do |rs| # lame, I know
        Url.from_rs(rs)[0]; # is there no easy "get one" option?
      end
    end
  end

  def self.get_only_or_nil_by_name_and_episode_number(name, episode_number)
    with_db do |conn|
      urls = conn.query("SELECT * FROM urls WHERE name = ? and episode_number = ?", name, episode_number) do |rs|
        Url.from_rs(rs);
      end
      if urls.size == 1
        return urls[0]
      else
        return nil
      end
    end
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
       @id = conn.exec("insert into urls (name, url, amazon_second_url, details, episode_number, episode_name, editing_status, wholesome_uplifting_level, good_movie_rating, image_local_filename, review, wholesome_review, count_downloads, amazon_prime_free_type, rental_cost, purchase_cost, total_time, subtitles, genre, original_rating, editing_notes, community_contrib) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", name, url, amazon_second_url, details, episode_number, episode_name, editing_status, wholesome_uplifting_level, good_movie_rating, image_local_filename, review, wholesome_review, count_downloads, amazon_prime_free_type, rental_cost, purchase_cost, total_time, subtitles, genre, original_rating, editing_notes, community_contrib).last_insert_id.to_i32
			 # get create_timestamp for free by its default crystal value
      else
       conn.exec "update urls set name = ?, url = ?, amazon_second_url = ?, details = ?, episode_number = ?, episode_name = ?, editing_status = ?, wholesome_uplifting_level = ?, good_movie_rating = ?, image_local_filename = ?, review = ?, wholesome_review = ?, count_downloads = ?, amazon_prime_free_type = ?, rental_cost = ?, purchase_cost = ?, total_time = ?, subtitles = ?, genre = ?, original_rating = ?, editing_notes = ?, community_contrib = ? where id = ?", name, url, amazon_second_url, details, episode_number, episode_name, editing_status, wholesome_uplifting_level, good_movie_rating, image_local_filename, review, wholesome_review, count_downloads, amazon_prime_free_type, rental_cost, purchase_cost, total_time, subtitles, genre, original_rating, editing_notes, community_contrib,  id
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
    @wholesome_review = ""
    @count_downloads = 0
    @amazon_prime_free_type = ""
    @rental_cost = 0.0
    @purchase_cost = 0.0
    @total_time = 0.0
		@create_timestamp = Time.now
		@subtitles = ""
    @genre = ""
    @original_rating = ""
    @editing_notes = ""
    @community_contrib = true
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

  def destroy_no_cascade
    with_db do |conn|
      conn.exec("delete from urls where id = ?", id)
    end
  end

  def url_lookup_params
    "url=#{url}&episode_number=#{episode_number}" # URI.escape?
  end

  def human_readable_company
    # get from url...
    check =  /\/\/([^\/]+\.[^\/]+).*/ #  //(.*)/ with a dot in it so splittable
    real_url = HTML.unescape(url) # want the slashes present :|
    if real_url =~ check
      host = $1.split(".")[-2]
    elsif url.includes?("://")
      host = url.split("://")[1].split("/")[0] # localhost:3000
    else
      host = url # ?? hope we never get here...
    end
    if amazon_prime_free_type != ""
      if amazon_prime_free_type == "Prime"
        host +=  " prime"
      else # assume Add-on
        host += " prime with add-on subscription"
      end
    else
      if host == "amazon"
        host += " (rent/buy)"
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
    out = ""
    if amazon_prime_free_type != ""
      out += "free (#{amazon_prime_free_type})"
    end
    if rental_cost > 0 || purchase_cost > 0
       if amazon_prime_free_type != ""
         out += ", or "
       end
       if rental_cost > 0
         out += " $%.2f (rent)" % rental_cost
       end
       if purchase_cost > 0
         out += " $%.2f (buy)" % purchase_cost
       end
    elsif human_readable_company == "youtube" # 0 is OK here :)
       out = "free (youtube)"
    else 
      # leave empty
    end
    out
  end

  def name_with_episode
    if episode_number != 0
      local_name = name
      if local_name.size > 150
        local_name = local_name[0..150] + "..."
      end
      "#{local_name}, Episode #{episode_number} : #{episode_name}"
    else
      name
    end
  end
 
  def delete_local_image_if_present_no_save
    if image_local_filename.present?
      [ "./public/movie_images/#{image_local_filename}", "./public/movie_images/small_#{image_local_filename}", "./public/movie_images/very_small_#{image_local_filename}" ].each{|file|
        if File.exists? file
          puts "Deleting #{file}"
          File.delete file # FileUtils.rm_r is broken :|
        end
      }
      image_local_filename = nil
    end
  end
	
	def download_image_url_and_save(full_url)
	  image_name = File.basename(full_url).split("?")[0] # attempt get normal name :|
          image_name = HTML.escape(image_name) # remove ('s etc.
          image_name = image_name.gsub("%", "_") # it's either this or carefully save the filename as Sing(2016) or unescape the name in the request or something phreaky...
          if image_name !~ /\.(jpg|png|jpeg|svg)$/i
            raise "download url appears to not be an image url like http://host/image.jpg please try another one... #{full_url}"
          end
	  outgoing_filename = "#{id}_#{image_name}"
	  local_full = "public/movie_images/#{outgoing_filename}"
	  File.write(local_full, download(full_url)) # guess this is OK non windows :|
          if !File.exists? local_full
            raise "unable to download that image file, please try a different one..."
          end
          delete_local_image_if_present_no_save # delete old now that we've downloaded new and have assured successful replacement :|
	  @image_local_filename = outgoing_filename
          create_thumbnail
          save
	end

        def create_thumbnail
          if image_local_filename.present?
            local_small = "public/movie_images/small_#{image_local_filename}"
            local_very_small = "public/movie_images/very_small_#{image_local_filename}"
            { local_small => "600x600", local_very_small => "300x300"}.each { |filename, resolution|
              command = "convert public/movie_images/#{image_local_filename}  -resize #{resolution}\\> #{filename}" # this will be either 600x400 or 400x600, both what we want :)
              if image_local_filename =~ /\.jpg$/
                command = command.sub("convert", "convert -strip -sampling-factor 4:2:0 -quality 85%") # attempt max compression
              end
	      raise "unable to thumnailify? #{id} #{command}" unless system(command)
            }
          end
        end
	
	def image_tag(size, postpend_html = "", want_small = true, want_very_small = false) # XXX use an enum or somefin
	  if image_local_filename.present?
                  name = image_local_filename # full :)
                  if want_small
                     name = "small_#{name}"
                  elsif want_very_small
                     name = "very_small_#{name}"
                  end
		  "<img src='/movie_images/#{name}' #{size}/>#{postpend_html}"
		else
		  ""
		end
	end

  def self.get_only_by_id(id)
    with_db do |conn|
      conn.query("SELECT * from urls where id = ?", id) do |rs|
         all = Url.from_rs(rs) # Index OOB if not there :|
         if all.size == 1
           return all[0]
         else
           raise "unable to find url with id #{id} size=#{all.size}"
         end
      end
    end
  end
end

class Tag

  JSON.mapping({
    id: Int32,
    start:   {type: Float64},
    endy: {type: Float64},
    category: {type: String},       
    subcategory: {type: String},   
    details: {type: String},     
    default_action: {type: String},
    age_maybe_ok: {type: Int32},
    url_id: Int32
  })
  DB.mapping({
    id: Int32,
    start:   {type: Float64},
    endy: {type: Float64},
    category: {type: String},       
    subcategory: {type: String},   
    details: {type: String},     
    default_action: {type: String},
    age_maybe_ok: {type: Int32},
    url_id: Int32
  })

  def self.all
    with_db do |conn|
      conn.query("SELECT * from tags order by url_id") do |rs|
         Tag.from_rs(rs);
      end
    end
  end

  
  def self.get_only_by_id(id)
    with_db do |conn|
      conn.query("SELECT * from tags where id = ?", id) do |rs|
         Tag.from_rs(rs)[0] # Index OOB if not there :|
      end
    end
  end
  
  def destroy_no_cascade
    with_db do |conn|
      conn.exec("delete from tags where id = ?", id)
    end
  end

  def destroy_in_tag_edit_lists
    with_db do |conn|
      conn.exec("delete from tag_edit_list_to_tag where tag_id = ?", id)
    end
  end

  def duration
    endy - start
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
    @default_action = "mute"
    @age_maybe_ok = 0
    @url_id = url.id
  end
  
  def save
    with_db do |conn|
      if @id == 0
        @id = conn.exec("insert into tags (start, endy, category, subcategory, details, default_action, age_maybe_ok, url_id) values (?,?,?,?,?,?,?,?)", @start, @endy, @category, @subcategory, @details,  @default_action, @age_maybe_ok, @url_id).last_insert_id.to_i32
      else
        conn.exec "update tags set start = ?, endy = ?, category = ?, subcategory = ?, details = ?, default_action = ?, age_maybe_ok = ? where id = ?", start, endy, category, subcategory, details, default_action, age_maybe_ok, id
      end
    end
  end

  def overlaps_any?(all_tags)
    all_tags.reject{|tag2| tag2.id == id}.each{|tag2|
      if (tag2.start >= start && tag2.start <= endy) || (tag2.endy >= start && tag2.endy <= endy)
        return tag2
      end
    }
    nil
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
  elsif minutes > 0  
    "%01dm %05.2fs" % [minutes, ts_seconds]
  else
    "%04.2fs" % [ts_seconds]
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

