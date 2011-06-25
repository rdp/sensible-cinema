#
# warning: somewhat scary/explicit!

# see subtitle_todo file





module SubtitleProfanityFinder






  def self.edl_output args



































    profanities = {'hell' => ['he..', true],
      'g' +
      'o' + 100.chr => '[deity]', 'g' +
      111.chr + 
      100.chr +
      's' => '[deity]s',
      'lord' => 'lo..', 'da' +
      'mn' => 'da..', 
      'f' +
      117.chr +
      99.chr +
      107.chr =>
      'f...',
      'bi' +
      'tc' + 104.chr => 'b.....',
      'bas' +
      'ta' + 'r' + 100.chr => 'ba.....',
      ('a' +
      's'*2) => ['a..', true],
      'breast' => 'br....',
      'jesus' => 'jes..',
      'chri' +
      'st'=> ['chri..', true], # allow for christian [?]
      'a realllly bad word' => ['test bad word', true]
    }

    incoming = File.read(args.shift)

    while args.length > 0
      prof = args.shift
      sanitized = args.shift
      profanities[prof] = sanitized
    end

    profanities = profanities.to_a.sort.reverse.map!{|profanity, sanitized|
      as_regexp = Regexp.new(profanity, Regexp::IGNORECASE)
      sanitized = Array(sanitized)
      if sanitized[1] # if so, want's to be single word...
        as_regexp = Regexp.new(profanity + "\s", Regexp::IGNORECASE)
      end
      [as_regexp, sanitized[0]]
    }

    output = ''
    # from a timestamp to a line with nothing :)
    for glop in incoming.scan(/\d\d:\d\d:\d\d.*?^$/m)
      for profanity, sanitized in profanities
        # dunno if we should force words to just start with this or contain it anywhere...
        # what about 'g..ly' for example?
        # or 'un...ly' ? I think we're ok there...

        if glop =~ profanity
          # create english-ified version
          # take out timing line, number line
          sanitized_glop = glop.lines.to_a[1..-1].join(' ')
          sanitized_glop.gsub!(/[\r\n]/, '') # flatten 3 lines to 1
          sanitized_glop.gsub!(/<(.|)(\/|)i>/i, '') # oddity
          sanitized_glop.gsub!(/[^a-zA-Z0-9']/, ' ') # kill weird stuff like ellipses
          sanitized_glop.gsub!(/\W\W+/, ' ') # remove duplicate "  " 's
          
          # sanitize
          for (prof2, sanitized2) in profanities
            sanitized_glop.gsub!(prof2, sanitized2)
          end

          # extract timing info
          timing_line = glop.split("\n").first.strip
          timing_line =~ /((\d\d:\d\d:\d\d),(\d\d\d) --> (\d\d:\d\d:\d\d),(\d\d\d))/
          # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
          output += %!"#{$2}.#{$3}" , "#{$4}.#{$5}", "profanity", "#{sanitized}", "#{sanitized_glop.strip}",\n!
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
    print SubtitleProfanityFinder.edl_output ARGV
  end
end
