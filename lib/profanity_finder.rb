# warning: somewhat explicit!











































profanities = {'hell' => 'heck', 'g' + 
'o' + 'd' => 'g..', 'lord' => 'lo..', 'damn' => 'da..', 'fu' +
'ck' => 'fu'}

incoming = File.read(ARGV[0])

for profanity, sanitized in profanities
  # dunno if we should force words to just start with this or contain it anywhere...
  # what about 'godly' for example?
  if incoming =~ Regexp.new(profanity, Regexp::IGNORECASE)
    p 'contains', sanitized
  end
end













