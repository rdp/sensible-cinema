# warning: somewhat explicit!











































profanities = {'hell' => 'heck', 'g' + 
'o' + 'd' => 'g..', 'lord' => 'lo..', 'da' + 
'mn' => 'da..', 'f' + 
'u' +
'c' + 'k' => 
'f...',
'bi' +
'tch' => 'b.....',
'ba' +
'stard' => 'ba.....'
}

incoming = File.read(ARGV[0])

for profanity, sanitized in profanities
  # dunno if we should force words to just start with this or contain it anywhere...
  # what about 'godly' for example?
  # or 'ungodly' ?
  if incoming =~ Regexp.new(profanity, Regexp::IGNORECASE)
    p 'contains', sanitized
  end
end













