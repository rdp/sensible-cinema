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

  def self.first
    with_db do |conn|
      conn.query("SELECT * from urls order by url, is_amazon_prime desc limit 1") do |rs|
        Url.from_rs(rs); # is there no easy "get one" option?
      end
    end[0]
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
       @id = conn.exec("insert into urls (name, url, amazon_second_url, details, amazon_episode_number, amazon_episode_name, editing_status, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, image_url, review, is_amazon_prime, rental_cost, purchase_cost, total_time) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", name, url, amazon_second_url, details, amazon_episode_number, amazon_episode_name, editing_status, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, image_url, review, is_amazon_prime, rental_cost, purchase_cost, total_time).last_insert_id.to_i32
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
    edls.each{|edl|
      edl.destroy
    }
    with_db do |conn|
      conn.exec("delete from urls where id = ?", id)
    end
  end

  def url_lookup_params
    "url=#{URI.escape url}&amazon_episode_number=#{amazon_episode_number}" # URI.escape == escapeComponent
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

