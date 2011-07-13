#
# warning: somewhat scary/explicit!

# see subtitle_todo file


require_relative 'edl_parser'


module SubtitleProfanityFinder


   def self.convert_to_regexps profanity_hash
    all_profanity_combinations = []
    profanity_hash.to_a.sort.reverse.each{|profanity, sanitized|
      as_regexp = Regexp.new(profanity, Regexp::IGNORECASE)
      if sanitized.is_a? Array
        is_single_word_profanity = true
        raise unless sanitized[1]
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
          sanitized_version = bracketized
          as_regexp = Regexp.new("\s" + permutation + "\s", Regexp::IGNORECASE)
          all_profanity_combinations << [as_regexp, ' ' + bracketized + ' ']
          as_regexp = Regexp.new("^" + permutation + "\s", Regexp::IGNORECASE)
          all_profanity_combinations << [as_regexp, bracketized + ' ']
          as_regexp = Regexp.new("\s" + permutation + "$", Regexp::IGNORECASE)
          all_profanity_combinations << [as_regexp, ' ' + bracketized]
          as_regexp = Regexp.new("^" + permutation + "$", Regexp::IGNORECASE)
          all_profanity_combinations << [as_regexp, bracketized]
        else
          all_profanity_combinations << [as_regexp, bracketized]
        end
      end
    }
    all_profanity_combinations
   end


  def self.edl_output incoming_filename, extra_profanity_hash = {}, subtract_from_each_beginning_ts = 0, add_to_end_each_ts = 0
     incoming = File.read(incoming_filename)
     raise if subtract_from_each_beginning_ts < 0
     raise if add_to_end_each_ts < 0






























    bad_profanities = {'hell' => ['he..', true],
      'g' +
      'o' + 100.chr => 'goodness', 'g' +
      111.chr + 
      100.chr +
      's' => 'deitys',
      'lord' => 'lo..', 'da' +
      'mn' => 'da..', 
      'f' +
      117.chr +
      99.chr +
      107.chr =>
      'f...',
      'sex' => 'sex',
      'genital' => 'genital', 'make love' => 'make love',
      'making love' => 'making love', 
      'love mak' => 'love mak',
      'bi' +
      'tc' + 104.chr => 'b....',
      'bas' +
      'ta' + 'r' + 100.chr => 'ba.....',
      ((arse = 'a' +
      's'*2)) => ['a..', true],
      arse + 'h' +
      'ole' => 'a..h...',
      arse + 'wipe' => 'a..w....',
      'breast' => 'br....',
      'jesus' => 'l...',
      'chri' +
      'st'=> ['chr...', true], # allow for christian[ity] [good idea or not?]
      'sh' +
       'i' + 't' => 'sh..',
      'a realllly bad word' => ['test edited bad word', true]
    }
    bad_profanities.merge! extra_profanity_hash    

   all_profanity_combinations = convert_to_regexps bad_profanities
    output = ''
    # from a timestamp to a line with nothing :)
    for glop in incoming.scan(/\d\d:\d\d:\d\d.*?^$/m)
      for profanity, (sanitized, whole_word) in all_profanity_combinations
        # dunno if we should force words to just start with this or contain it anywhere...
        # what about 'g..ly' for example?
        # or 'un...ly' ? I think we're ok there...

        if glop =~ profanity
          # create english-ified version
          # take out timing line, number line
          sanitized_glop = glop.lines.to_a[1..-1].join(' ')
          sanitized_glop.gsub!(/[\r\n]/, '') # flatten 3 lines to 1
          sanitized_glop.gsub!(/<(.|)(\/|)i>/i, '') # kill <i> 
          sanitized_glop.gsub!(/[^a-zA-Z0-9'""]/, ' ') # kill weird stuff like ellipses
          sanitized_glop.gsub!(/\W\W+/, ' ') # remove duplicate "  " 's
          
          # sanitize
          for (prof2, (sanitized2, whole_word2)) in all_profanity_combinations
            if sanitized_glop =~ prof2
              sanitized_glop.gsub!(prof2, sanitized2)
            end
          end
          
          # because we have duplicate's for the letter l/i, refactor [[[profanity]]]
          sanitized_glop.gsub!(/\[+/, '[')
          sanitized_glop.gsub!(/\]+/, ']')
          
          # extract timing info
          timing_line = glop.split("\n").first.strip
          timing_line =~ /((\d\d:\d\d:\d\d),(\d\d\d) --> (\d\d:\d\d:\d\d),(\d\d\d))/
          # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
          ts_begin = "#{$2}.#{$3}"
          ts_begin = EdlParser.translate_string_to_seconds ts_begin
          ts_begin  -= subtract_from_each_beginning_ts
          ts_begin = EdlParser.translate_time_to_human_readable ts_begin, true
          ts_end = "#{$4}.#{$5}"
          ts_end = EdlParser.translate_string_to_seconds ts_end
          ts_end += add_to_end_each_ts
          ts_end = EdlParser.translate_time_to_human_readable ts_end, true
          output += %!"#{ts_begin}" , "#{ts_end}", "profanity", "#{sanitized.gsub(/[\[\]]/, '').strip}", "#{sanitized_glop.strip}",\n!
          break
        end

      end

    end
    output

  end
end

if $0 == __FILE__
  if ARGV.empty?
    p 'syntax: filename.srt [prof1 sanitized_equivalent1 prof2 sanitized_equivalent2 ...]'
    exit
  else
    print SubtitleProfanityFinder.edl_output ARGV.first
  end
end
