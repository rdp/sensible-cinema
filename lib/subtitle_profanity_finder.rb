#
# warning: somewhat scary/explicit!

# see also todo.subtitle file, though what's here is mostly pretty well functional
begin
  require 'sane'
rescue LoadError
  require 'rubygems'
  require 'sane'
end
require_relative 'edl_parser'
require 'ostruct'

module SubtitleProfanityFinder

   # splits into timestamps -> timestamps\ncontent blocks
   def self.split_to_entries subtitles
     all = subtitles.scan(/\d\d:\d\d:\d\d.*?^$/m)
     all.map{|glop|
       text = glop.lines.to_a[1..-1].join(' ')
       # create english-ified version
       text.gsub!(/[\r\n]/, '') # flatten 3 lines to 1
       text.gsub!(/<(.|)(\/|)i>/i, '') # kill <i> 
       text.gsub!(/[^a-zA-Z0-9'""]/, ' ') # kill weird stuff like ellipseses
       text.gsub!(/\W\W+/, ' ') # remove duplicate "  " 's now since we may have inserted many
       # extract timing info
       timing_line = glop.split("\n").first.strip
       # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
       timing_line =~ /((\d\d:\d\d:\d\d),(\d\d\d) --> (\d\d:\d\d:\d\d),(\d\d\d))/
       raise unless $1 && $2 && $3 && $4
       ts_begin = "#{$2}.#{$3}"
       ts_end =  "#{$4}.#{$5}"
       out = OpenStruct.new
       out.beginning = ts_begin
       out.ending = ts_end
       out.text = text.strip
       out
     }
   end

   # convert string to regexp, also accomodating for "full word" type profanities
   def self.convert_to_regexps profanity_hash
    all_profanity_combinations = []
    profanity_hash.to_a.sort.reverse.each{|profanity, sanitized|
      as_regexp = Regexp.new(profanity, Regexp::IGNORECASE)
      if sanitized.is_a? Array
        is_single_word_profanity = true
        raise unless sanitized[1] == :full_word
        raise unless sanitized.length == 2
        sanitized = sanitized[0]
      end
      
      permutations = [profanity]
      if profanity =~ /l/
        permutations << profanity.gsub(/l/i, 'i')
      end
      if profanity =~ /i/
        permutations << profanity.gsub(/i/i, 'l')
      end
      
      bracketized = '[' + sanitized + ']'
      
      for permutation in permutations
        if is_single_word_profanity
          # oh wow this is ughly...
          as_regexp = Regexp.new("(?:\s|^)" + permutation + "(?:\s|$|[^a-zA-Z])", Regexp::IGNORECASE)
          all_profanity_combinations << [as_regexp, ' ' + bracketized + ' '] # might introduce an extra space in there, but that's prolly ok since they're full-word already
        else
          all_profanity_combinations << [as_regexp, bracketized]
        end
      end
    }
    all_profanity_combinations
  end

  def self.edl_output incoming_filename, extra_profanity_hash = {}, subtract_from_each_beginning_ts = 0, add_to_end_each_ts = 0, beginning_srt = "00:00", beginning_actual_movie = "00:00", ending_srt = "10:00:00", ending_actual = "10:00:00"
    edl_output_from_string File.read(incoming_filename), extra_profanity_hash, subtract_from_each_beginning_ts, add_to_end_each_ts, beginning_srt, beginning_actual_movie, ending_srt, ending_actual
  end
  
  private
  def self.edl_output_from_string subtitles, extra_profanity_hash, subtract_from_each_beginning_ts, add_to_end_each_ts, starting_timestamp_given_srt, starting_timestamp_actual, ending_srt, ending_actual, include_minor_profanities=true
     subtitles.gsub!("\r\n", "\n")
     raise if subtract_from_each_beginning_ts < 0 # these have to be positive...in my twisted paradigm
     raise if add_to_end_each_ts < 0

     starting_timestamp_given_srt = EdlParser.translate_string_to_seconds(starting_timestamp_given_srt)
     starting_timestamp_actual = EdlParser.translate_string_to_seconds(starting_timestamp_actual)
     ending_srt = EdlParser.translate_string_to_seconds(ending_srt)
     ending_actual = EdlParser.translate_string_to_seconds ending_actual

     # accomodate for both styles of rewrite, except it messes up the math...delete this soon...
     # difference = starting_timestamp_given_srt - starting_timestamp_actual
     # subtract_from_each_beginning_ts += difference
     # add_to_end_each_ts -= difference

#     you minus the initial srt time... (given)
#     ratio = (end actual - init actual/ end given - init given)*(how far you are past the initial srt) plus initial actual
     multiply_by_this_factor = (ending_actual - starting_timestamp_actual)/(ending_srt - starting_timestamp_given_srt)

     multiply_proc = proc {|you|
      ((you - starting_timestamp_given_srt) * multiply_by_this_factor) + starting_timestamp_actual
    }  





























    bad_profanities = {'hell' => ['he..', :full_word],
      'g' +
      'o' + 100.chr => 'goodness', 'g' +
      111.chr + 
      100.chr +
      's' => 'deitys',
      'meu deus' => 'lo..',
      'lord' => 'lo..', 'da' +
      'mn' => 'da..', 
      'f' +
      117.chr +
      99.chr +
      107.chr =>
      'f...',
      'allah' => 'all..',
      'bi' +
      'tc' + 104.chr => 'b....',
      'bas' +
      'ta' + 'r' + 100.chr => 'ba.....',
      ((arse = 'a' +
      's'*2)) => ['a..', :full_word],
      arse + 'h' +
      'ole' => 'a..h...',
      'dieu' => ['deity', :full_word], # TODO fails...
      arse + 'wipe' => 'a..w....',
      'jes' +
      'u' + 's' => 'j....',
      'chri' +
      'st'=> ['chr...', :full_word], # allow for christian[ity] [good idea or not?]
      'sh' +
       'i' + 't' => 'sh..',
      'a realllly bad word' => ['test edited bad word', :full_word]
    }
    
    bad_profanities.merge! extra_profanity_hash # LODO make easier to use...

    semi_bad_profanities = {}
    ['bloody', 'moron', 'breast', 'idiot', 
      'sex', 'genital', 
      'boob', 
      'make love', 
      'making love', 'love mak', 
      'dumb', 'suck', 'piss'
	  ].each{|name|
      semi_bad_profanities[name] = name
    }
    semi_bad_profanities['crap'] = ['crap', :full_word]
    semi_bad_profanities['butt'] = ['butt', :full_word]
    # butter?

    all_profanity_combinationss = [convert_to_regexps(bad_profanities)]
    if include_minor_profanities
      all_profanity_combinationss += [convert_to_regexps(semi_bad_profanities)]
    end
    
    output = ''
    for all_profanity_combinations in all_profanity_combinationss
      output += "\n"
      for entry in split_to_entries(subtitles)
        text = entry.text
        for profanity, (sanitized, whole_word) in all_profanity_combinations
  
          if text =~ profanity
            # sanitize/euphemize the subtitle text...
            for all_profanity_combinations2 in all_profanity_combinationss
              for (prof2, (sanitized2, whole_word2)) in all_profanity_combinations2
                if text =~ prof2
                  text.gsub!(prof2, sanitized2)
                end
              end
            end
            
            # because we now have duplicate's for the letter l/i, refactor [[[profanity]]]
            text.gsub!(/\[+/, '[')
            text.gsub!(/\]+/, ']')
            
            ts_begin = EdlParser.translate_string_to_seconds entry.beginning
            ts_begin  -= subtract_from_each_beginning_ts
            ts_begin = multiply_proc.call(ts_begin)
            ts_begin = EdlParser.translate_time_to_human_readable ts_begin, true
            ts_end = EdlParser.translate_string_to_seconds entry.ending
            ts_end += add_to_end_each_ts
            ts_end = multiply_proc.call(ts_end)
            ts_end = EdlParser.translate_time_to_human_readable ts_end, true
            unless output.contain? ts_begin # some previous profanity already found this line :P
              output += %!  "#{ts_begin}" , "#{ts_end}", "profanity", "#{sanitized.gsub(/[\[\]]/, '').strip}", "#{text}",\n!
            end
          end
        end
      end
    end
    output
  end
end

if $0 == __FILE__
  if ARGV.empty?
    p 'syntax: [filename.srt | [--create-edl|--create-edl-including-minor-profanities] input_name.srt output_name.edl]'
    exit
  elsif ARGV[0].in? ['--create-edl', '--create-edl-including-minor-profanities']
    require_relative 'mplayer_edl'
    incoming_filename = ARGV[1]
    include_minors = true if ARGV[0] == '--create-edl-including-minor-profanities'
    mutes = SubtitleProfanityFinder.edl_output_from_string File.read(incoming_filename), {}, 0, 0, "00:00", "00:00", "10:00:00", "10:00:00", include_minors
    specs = EdlParser.parse_string %!"mutes" => [#{mutes}]!
    File.write(ARGV[2], MplayerEdl.convert_to_edl(specs))
    puts "wrote to #{ARGV[2]}"
  else
    print SubtitleProfanityFinder.edl_output ARGV.first
  end
end
