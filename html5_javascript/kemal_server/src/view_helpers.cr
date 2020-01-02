
def if_present_with_break(value, add_this_before = "")
  if value.to_s.size > 0 && value != 0
    add_this_before + " " + value.to_s + "<br/>"
  end
end

def table_row_or_nothing(first_cell, second_cell)
  if second_cell.to_s.size > 0 && second_cell != 0
    "<tr><td>#{first_cell}</td><td>#{second_cell}</td></tr>";
  end
end

def google_search_string(url)
   google_search = URI.encode_www_form(url.name + " poster", space_to_plus: true)
   if url.episode_number != 0
     google_search += URI.encode_www_form(" " + url.episode_number.to_s + " " + url.episode_name, space_to_plus: true)
   end
   google_search
end

def mobile?(env)
  ua = env.request.headers["User-Agent"]? 
  puts "ua=#{ua}"
  ua =~ /Mobile|iP(hone|od|ad)|Android|BlackBerry|IEMobile|Kindle|NetFront|Silk-Accelerated|(hpw|web)OS|Fennec|Minimo|Opera M(obi|ini)|Blazer|Dolfin|Dolphin|Skyfire|Zune/
end

def android_mobile?(env)
  ua = env.request.headers["User-Agent"]? 
  mobile?(env) && ua =~ /Android /
end

def chrome_desktop?(env)
  ua = env.request.headers["User-Agent"]? 
  if ua =~ /Chrome|CriOS/ && ua !~ /Aviator|ChromePlus|coc_|Dragon|Edge|Flock|Iron|Kinza|Maxthon|MxNitro|Nichrome|OPR|Perk|Rockmelt|Seznam|Sleipnir|Spark|UBrowser|Vivaldi|WebExplorer|YaBrow/ && !mobile?(env)
    true
  else
    false
  end
end

def my_android?(env)
  ua = env.request.headers["User-Agent"]? 
  ua =~ /PlayItMyWay/
end

def editor?(env)
  if logged_in?(env)
    logged_in_user(env).editor
  else
    false
  end
end

def admin?(env)
  logged_in?(env) && logged_in_user(env).is_admin
end

def humanize_category(category)
    category = category.to_s # if it's a symbol, which it can be...
    category = "clothing/kissing etc" if category == "physical"
    category = "verbal" if category == "profanity"
    category = "substance use" if category == "substance-abuse"
    category = "credits/other" if category == "movie-content"
    # else [violence, suspense] stay XXXX constantize :\
    category
end

struct Bool
  def <=>(other : Bool)
    if self == other
      return 0
    elsif self
      return 1
    else
      return -1
    end
  end
end

def tags_by_category_with_size(url)
  url.tags.group_by{|tag| tag.category}.select{|category, tags| tags.size > 1 }.to_a.sort_by{|cat, tags| cat == "movie-content"}
    .map{ |category, tags| 
    category = humanize_category(category)
    "#{category}: #{tags.size}"
  }.join(", ")
end

# from https://github.com/crystal-lang/crystal/pull/4555/commits/1a6f50250d9cbdc5354e80eeaec48a0e71559ee0 hope it wurx
ESCAPE_JAVASCRIPT_SUBST = {
    '\''     => "\\'",
    '"'      => "\\\"",
    '\\'     => "\\\\",
    '\u2028' => "&#x2028;",
    '\u2029' => "&#x2029;",
    '\n'     => "\\n",
    '\r'     => "\\n",
} # might not be enough :|

def escape_javascript(string : String) : String
  string.gsub("\r\n", "\n").gsub(ESCAPE_JAVASCRIPT_SUBST).gsub("</", "<\\/")
end
