#
# warning: somewhat scary/explicit down there!
# see also todo.subtitle file, though what"s here is mostly pretty well functional/complete
#
require "./edl_parser"
require "./sane"

module SubtitleProfanityFinder
   @@expected_min_size = 10 # so unit tests can change it
   def self.expected_min_size=(new_min)
     @@expected_min_size = new_min
   end

   # splits into timestamps -> timestamps\ncontent blocks
   def self.split_to_entries(subtitles_raw_text)
     # p subtitles_raw_text.valid_encoding? # no crystal equiv.
     # also crystal length => size hint plz
     all = subtitles_raw_text.gsub("\r\n", "\n").scan(/^\d+\n\d\d:\d\d:\d\d.*?^$/m) # gsub line endings so that it parses right when linux reads a windows file <huh?>
     all = all.map{ |glop|
       lines = glop[0].lines.to_a
       index_line = lines[0]
       timing_line = lines[1].strip
       text = lines.to_a[2..-1].join("") # they still have separating "\n""s
       # create english-ified version
       test = text.gsub(/<(.|)(\/|)i>/i, "") # kill <i> type things
       text = text.gsub(/[^a-zA-Z0-9\-!,.\?"\n\(\)]/, " ") # kill weird stuff like ellipseses, also quotes would hurt so kill them too
       text = text.gsub(/  +/, " ") # remove duplicate "  " "s now since we may have inserted many
       # extract timing info
       # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
       timing_line =~ /((\d\d:\d\d:\d\d),(\d\d\d) --> (\d\d:\d\d:\d\d),(\d\d\d))/
       ts_begin = "#{$2}.#{$3}"
       ts_end = "#{$4}.#{$5}"
       out = { index_number: index_line.strip.to_i,
         beginning_time: EdlParser.translate_string_to_seconds(ts_begin),
         ending_time: EdlParser.translate_string_to_seconds(ts_end),
         text: text.strip,
         single_line_text: ""
       }
       # TODO add_single_line_minimized_text_from_multiline(out)
       out
     }
     if all.size < @@expected_min_size
       raise "unable to parse subtitle file? size=#{all.size}"
     end

     # strip out auto inserted trailers/headers
     reg =  / by|download| eng|www|http|sub/i
     while all[0][:text] =~ reg
      all.shift
     end
     while all[-1][:text] =~ reg
      all.pop
     end
     all
   end

   def self.add_single_line_minimized_text_from_multiline(entry)
     entry[:single_line_text] = entry[:text].strip.gsub(/^[- ,_\.]+/, "").gsub(/[- ,_]+$/, "").gsub(/[\r\n]/, " ")
   end

   # convert string to regexp, also accomodating for "full word" type profanities
   def self.convert_to_regexps(profanity_hash)
    all_profanity_combinations = [] of {Regex, String, String}
    profanity_hash.to_a.reverse.each{ |profanity, sanitized| #  used to sort...
      as_regexp = Regex.new(profanity, Regex::Options::IGNORE_CASE)
      if sanitized.is_a? Array
        # like "bad word" => ["vain use", :partial_word, "deity"]
        raise "huh3" unless sanitized.size.in? [2, 3]
        raise "huh4" unless sanitized[1].in? [:full_word, :partial_word]
        is_single_word_profanity = true if sanitized[1] == :full_word
        if sanitized.size == 3
          category = sanitized[2].as(String)
        end
        sanitized = sanitized[0].as(String)
      end
      
      permutations = [profanity]
      if profanity =~ /l/
        permutations << profanity.gsub(/l/i, "i")
      end
      if profanity =~ /i/
        permutations << profanity.gsub(/i/i, "i")
      end
      
      replace_with = "[" + sanitized.to_s + "]"
      category ||= sanitized
      
      permutations.each{ |permutation| 
        if is_single_word_profanity
	  # \s is whitespace
          as_regexp = Regex.new("(?:\s|^|[^a-zA-Z])" + permutation + "(?:\s|$|[^a-zA-Z])", Regex::Options::IGNORE_CASE)
          all_profanity_combinations << {as_regexp, category, " " + replace_with + " "} # might introduce an extra space in there, but that"s prolly ok since they"re full-word already, and we collapse them
        else
          all_profanity_combinations << {as_regexp, category, replace_with}
        end
      }
    }
    all_profanity_combinations
  end

  def self.edl_output(incoming_filename, subtract_from_each_beginning_ts = 0, add_to_end_each_ts = 0, 
               beginning_srt = 0.0, beginning_actual_movie = 0.0, ending_srt = 7200.0, ending_actual = 7200.0)
    # jruby is unkind to invalid encoding input, and these can come from "all over" unfortunately, and it doesn"t guess it right [?] ai ai so scrub
    contents = File.read(incoming_filename)
    edl_output_from_string(contents, subtract_from_each_beginning_ts, add_to_end_each_ts, beginning_srt, beginning_actual_movie, ending_srt, ending_actual)[0]
  end
  
  # **_time parameters are expected to be floats...
  def self.edl_output_from_string(subtitles, subtract_from_each_beginning_ts, add_to_end_each_ts, starting_time_given_srt, starting_time_actual, ending_srt_time, ending_actual_time, include_minor_profanities=true) # lodo may not need include_minor_profs :P
     raise "huh" if subtract_from_each_beginning_ts < 0 # these have to be positive...in my twisted paradigm
     raise "huh2" if add_to_end_each_ts < 0
     # no crystal equiv? subtitles = subtitles.scrub # invalid UTF-8 creeps in at times... ruby 2.1+





























    bad_profanities = {"hell" => ["h...", :full_word],
      "g" +
      111.chr + 
      100.chr => ["___", :partial_word, "deity"], "g" +
      111.chr + 
      100.chr +
      "s" => "deitys",
      "meu deus" => "l...",
      "lo" + 
	  "rd" => "l...", "da" +
      "mn" => "d...", 
      "f" +
      117.chr +
      99.chr +
      107.chr =>
      "f...",
      "allah" => "all..",
      "bi" +
      "tc" + 104.chr => "b....",
      "bas" +
      "ta" + 
	  "r" + 100.chr => "ba.....",
      ((arse = "a" +
      "s"*2)) => ["a..", :full_word],
      arse + "h" +
      "ole" => "a..h...",
      "dieu" => ["deity", :full_word],
      arse + "w" +
      "ipe" => "a..w...",
      "jes" +
      "u" + "s" => ["___", :partial_word, "deity"],
      "chri" +
      "st"=> ["___", :full_word, "deity"], # allow for christian[ity] 
      "sh" +
       "i" + "t" => "sh..",
      "cu" +
      "nt" => "c...",
      "cock" +
	  "su" + 
	  "cker" => "cock......",
	  "bloody" => "bloo.."
    }
	
    semi_bad_profanities = {} of String => String | Array(String | Symbol)
    ["moron", "breast", "idiot", 
      "sex", "genital", 
	  "naked", 
      "boob", 
      "tits",
      "make love", "pen" +
	  "is",
      "pu" +
	  "ssy",
	  "gosh",
	  "whore",
	  "debauch",
      "come to bed",
      "lie with",
      "making" + 
	    " love", "love mak", 
      "dumb", "suck", "piss", "c" +
	    "u" + "nt",
	    "d" + "ick", "v" +
		"ag" +
	    "i" + 
		"na",
		"int" +
		"er" +
		"course"
	  ].each{|name|
      semi_bad_profanities[name] = name
    }
	
	["panties", "crap", "butt", "dumb", "fart"].each{|word|
	  semi_bad_profanities[word] = [word, :full_word]
	}
	
    all_profanity_combinationss = [convert_to_regexps(bad_profanities)]
    if include_minor_profanities
      all_profanity_combinationss += [convert_to_regexps(semi_bad_profanities)]
    end
    
    output = ""
    entries = split_to_entries(subtitles)
    all_profanity_combinationss.each{|all_profanity_combinations|
      output += "\n" # some space between greater and lesser prof"s
      entries.each{ |entry|
        text = entry[:text]
        ts_begin = entry[:beginning_time]

        ts_begin -= subtract_from_each_beginning_ts
        
        ts_end = entry[:ending_time]
        ts_end += add_to_end_each_ts
        found_category = nil
        all_profanity_combinations.each{ |profanity, category, sanitized|
          if text =~ profanity
            found_category = category
            break
          end
        }
        
        if found_category
          # sanitize/euphemize the subtitle text for all profanities...
          all_profanity_combinationss.each{ |all_profanity_combinations2|
            all_profanity_combinations2.each{|profanity, category, sanitized|
              text = text.gsub(profanity, sanitized)
            }
          }
          
          # because we now have duplicate"s for the letter l/i, refactor [[[word]]] to just [word]
          text = text.gsub(/\[+/, "[")
          text = text.gsub(/\]+/, "]")
          # crstayl gah! entry[:text] = text
          #add_single_line_minimized_text_from_multiline entry
          text = text.gsub(/[\r\n]|\n/, " ") # flatten up to 3 lines of text to just 1
          ts_begin_human = EdlParser.translate_time_to_human_readable ts_begin, true
          ts_end_human = EdlParser.translate_time_to_human_readable ts_end, true
          unless output.includes? ts_begin_human # i.e. some previous profanity already found this line :P
            output += %{  "#{ts_begin_human}" , "#{ts_end_human}", "profanity", "#{found_category}", "#{text}",\n}
          end
        end
      }
    }
    [output.strip, entries]
  end
end

if ARGV[0] == "--create-edl" # then .srt name
  incoming_filename = ARGV[1]
  stuff = SubtitleProfanityFinder.edl_output incoming_filename
  puts "got #{stuff.inspect}"
end
