#
# warning: somewhat scary/explicit!

# see subtitle_todo file










































profanities = {'hell' => 'heck', 
  'g' + 
'o' + 'd' => 'g..', 'go' +
'd' +
's' => 'g...', 'lord' => 'lo..', 'da' + 
'mn' => 'da..', 'f' + 
 117.chr +
99.chr + 
 107.chr => 
'f...',
'bi' +
'tc' + 104.chr => 'b.....',
'bas' +
'tard' => 'ba.....',
('a' +
 's'*2) => 'a..',
'breast' => 'br....'
}

# sat...

if ARGV.empty?
  p 'syntax: filename.srt prof1 sanitized_equivalent1 prof2 sanitized_equivalent2'
  exit
end

incoming = File.read(ARGV.shift)

while ARGV.length > 0
  prof = ARGV.shift
  sanitized = ARGV.shift
  profanities[prof] = sanitized  
end

profanities = profanities.to_a.sort.reverse.map!{|profanity, sanitized| [Regexp.new(profanity, Regexp::IGNORECASE), sanitized]}

found_any = false

for glop in incoming.scan(/\d\d:\d\d:\d\d.*?^\d+$/m)

for profanity, sanitized in profanities
  # dunno if we should force words to just start with this or contain it anywhere...
  # what about 'g..ly' for example?
  # or 'un...ly' ?
  
  if glop =~ profanity
    found_any = true
    
    # create english-ified version
    # take out timing line, number line
    sanitized_glop = glop.lines.to_a[1..-2].join('')
    sanitized_glop.gsub!(/[\r\n]/, '') # flatten 3 lines to 1
    sanitized_glop.gsub!(/<i>/, '') # oddity
    sanitized_glop.gsub!(/[^a-zA-Z0-9]/, ' ') # kill weird stuff like ellipses
    
    
    # sanitize
    for (prof2, sanitized2) in profanities
      sanitized_glop.gsub!(prof2, sanitized2)
    end
    
    # extract timing info
    timing_line = glop.split("\n").first.strip
    timing_line =~ /((\d\d:\d\d:\d\d),(\d\d\d) --> (\d\d:\d\d:\d\d),(\d\d\d))/
    # "00:03:00.0" , "00:04:00.0", "violence", "of some sort",
    puts %!"#{$2}.#{$3}" , "#{$4}.#{$5}", "profanity", "#{sanitized}", "#{sanitized_glop.strip}",! 
  end
  
end


end

p 'no profanity detected' unless found_any