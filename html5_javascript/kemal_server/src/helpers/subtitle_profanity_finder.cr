require "./std_lib_helpers"
require "./profanities.cr"
require "./subcategories.cr"

module SubtitleProfanityFinder
   @@required_min_num_subs_per_file = 10 # so unit tests can change it
   def self.required_min_num_subs_per_file=(new_min)
     @@required_min_num_subs_per_file = new_min
   end

   # splits into NamedTuple, this is just .srt style
   def self.split_from_srt(subtitles_raw_text)
     subtitles_raw_text = subtitles_raw_text.gsub("\r\n", "\n")  # gsub line endings first so that it parses right when linux reads a windows file [maybe?]
     entries = subtitles_raw_text.scan(/^\d+\n\d\d:\d\d:\d\d.*?^$/m)
     all = entries.map{ |glop|
       lines = glop[0].lines.to_a
       index_line = lines[0]
       timing_line = lines[1].strip
       text = lines.to_a[2..-1].join(" ")
       # create english-ified version
       text = text.gsub(/<(.|)(\/|)i>/i, "") # kill <i> type things, which are in there sometimes :|
       text = text.gsub(/[^'a-zA-Z0-9\-!,.\?"\n\(\)]/, " ") # kill weird stuff like ellipseses, also quotes would hurt so kill them too
       text = text.gsub(/  +/, " ") # remove duplicate "  " "s now since we may have inserted many
       text = text.strip
       # extract timing info
       # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
       timing_line =~ /((\d\d:\d\d:\d\d),(\d\d\d) --> (\d\d:\d\d:\d\d),(\d\d\d))/
       ts_begin = "#{$2}.#{$3}"
       ts_end = "#{$4}.#{$5}"
       out = { index_number: index_line.strip.to_i,
         beginning_time: translate_string_to_seconds(ts_begin),
         ending_time: translate_string_to_seconds(ts_end),
         text: text,
       }
       # add_single_line_minimized_text_from_multiline(text)
       out
     }
     if all.size < @@required_min_num_subs_per_file
       raise "unable to parse subtitle file? size=#{all.size} from #{subtitles_raw_text}"
     end

     # strip out auto inserted trailer/header subtitles since they don't actually match up to text
     reg =  / by|download| eng|www|http|subtitle|sub-title/i
     while all[0][:text] =~ reg
      all.shift
     end
     while all[-1][:text] =~ reg
      all.pop
     end
     all
   end

   def self.convert_to_regexps(profanity_tuples)
    all_profanity_combinations = [] of {Regex, String, String} # Strings = subcategory, replace_with :|
    profanity_tuples.each{ |profanity_tuple|
      category = profanity_tuple[:category] # actually sub category within profanity
      subcats = subcategory_map.map{ |category, entries| entries.map{|e| e[:db_name] } }.flatten
      raise "unknown cat, please report [#{category}] option! available are #{subcats}" unless subcats.includes?(category) # these should match! :|
      profanity = profanity_tuple[:bad_word]
      sanitized = profanity_tuple[:sanitized]
      
      permutations = [profanity]
      if profanity =~ /l/
        permutations << profanity.gsub(/l/i, "i")
      end
      if profanity =~ /i/
        permutations << profanity.gsub(/i/i, "i")
      end
      
      replace_with = "_" + sanitized + "_"
      
      permutations.each{ |permutation| 
        # \s is whitespace, but escape it right :|
        word_begins_with_this_regex = "(?:\\s|^|[^a-z])"
        word_ending_after =  "(?:\\s|$|[^a-z])"
        if profanity_tuple[:type] == :full_word_only
          as_regexp = Regex.new(word_begins_with_this_regex + permutation + word_ending_after, Regex::Options::IGNORE_CASE)
          all_profanity_combinations << {as_regexp, category, " " + replace_with + " "} # we'll be replacing (white space)(word)(white space) so don't lose the whitespace...kind of...
        elsif profanity_tuple[:type] == :beginning_word
          # basically just he.. :|
          # so do either he.. or he.... # avoid hello LOL
          # full word he.. too
          all_profanity_combinations << { Regex.new(word_begins_with_this_regex + permutation + word_ending_after, Regex::Options::IGNORE_CASE), category, " " + replace_with + " "}
          # he..... leave as much in as possible to kind of guess what it was...
          all_profanity_combinations << {Regex.new(word_begins_with_this_regex + permutation + "[a-z][a-z]", Regex::Options::IGNORE_CASE), category, " " + replace_with  + ".."} # close enough
          # leave in the plural for fun :|
          all_profanity_combinations << {Regex.new(word_begins_with_this_regex + permutation + "s", Regex::Options::IGNORE_CASE), category, " " + replace_with} # the replacement is still off.gah...
        else
          raise "unknown type #{profanity_tuple}" unless profanity_tuple[:type] == :partial
          as_regexp = Regex.new(profanity, Regex::Options::IGNORE_CASE) # just normal here
          all_profanity_combinations << {as_regexp, category, replace_with}
        end
      }
    }
    all_profanity_combinations
  end

  def self.mutes_from_amazon_string(raw_subs)
    raw_subs = raw_subs.scrub # invalid UTF-8 creeps in at times...
    entries = split_from_amazon(raw_subs)
    detect_profanities(entries)
  end

  def self.split_from_amazon(raw_subs)
    out = raw_subs.lines.map{|line|
      translate_amazon_line_to_entry(line)
    }.compact
    out
  end

  def self.translate_amazon_line_to_entry(line)
    # <tt:p begin="00:03:07.321" end="00:03:10.924">but I say wonder and magic<tt:br/>don't come easy, pal.</tt:p>
    timestamp_regex = /begin="(\d\d:\d\d:\d\d.\d\d\d)" end="(\d\d:\d\d:\d\d.\d\d\d)".*?>(.*)/
    if line =~ timestamp_regex
       text = $3.gsub(/<tt:[^>]+>/, " ").gsub(/<\/tt:[^>]+>/, " ") # strip out internal <tt:br> or <span> or anything like it :|
       { 
         beginning_time: translate_string_to_seconds($1),
         ending_time: translate_string_to_seconds($2),
         text: text,
       } 
    else
      nil
    end
  end

  def self.mutes_from_srt_string(subtitles)
    subtitles = subtitles.scrub # invalid UTF-8 creeps in at times...
    entries = split_from_srt(subtitles)
    detect_profanities(entries)
  end

  def self.detect_profanities(entries)
    all_profanity_combinationss = [convert_to_regexps(Bad_profanities)] # double array so we can do the lesser ones second
    all_profanity_combinationss += [convert_to_regexps(Semi_bad_profanities)] # include 'em why not?
    
    mutes = [] of NamedTuple(start: Float64, endy: Float64, category: String, details: String)
    euphemized = [] of NamedTuple(start: Float64, endy: Float64, category: String | Nil, details: String) 
    all_profanity_combinations = all_profanity_combinationss.flatten # used to care about grouping them :|
      entries.each{ |entry|
        text = entry[:text]
        ts_begin = entry[:beginning_time]
        ts_end = entry[:ending_time]
        found_category = nil
        all_profanity_combinations.each{ |profanity_reg, category, sanitized|
          if text =~ profanity_reg
            found_category = category # just get the first, assume it's the worst [?]
            break
          end
        }
        
        if found_category
          # we're actually going to sanitize/euphemize the subtitle text for every profanity now...since our found_category was "its first" the major/initial euephemize should match, phew...
          all_profanity_combinationss.each{ |all_profanity_combinations2|
            all_profanity_combinations2.each{|profanity_reg, category, sanitized|
              if text =~ profanity_reg
                text = text.gsub(profanity_reg, sanitized)
              end
            }
          }
          unless mutes.index{|me| me[:start] == ts_begin} # i.e. some previous profanity combination already found this line :|
            mutes << {start: ts_begin, endy: ts_end, category: found_category, details: text}
          end
        end
        euphemized << {start: ts_begin, endy: ts_end, category: found_category, details: text}
      }
    return mutes, euphemized
  end
  
  # this one is 1:01:02.0 => 36692.0
  # its reverse is this: translate_time_to_human_readable
  def self.translate_string_to_seconds(s)
    # might actually already be a float, or int, depending on the yaml
    # int for 8 => 9 and also for 1:09 => 1:10
    if s.is_a? Number
      return s.to_f # easy out.
    end
    
    s = s.strip
    # s is like 1:01:02.0
    total = 0.0
    seconds = nil
    seconds = s.split(":")[-1]
    raise "does not look like a timestamp? " + seconds.inspect unless seconds =~ /^\d+(|[,.]\d+)$/
    seconds = seconds.gsub("," , ".")
    total += seconds.to_f
    minutes = s.split(":")[-2] || "0"
    total += 60 * minutes.to_i
    hours = s.split(":")[-3] || "0"
    total += 60* 60 * hours.to_i
    total
  end
  
end

