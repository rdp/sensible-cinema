seconds = (ARGV[0] || 1000).to_f
p 'syntax: second to convert, first conversion ratio, second conversation ratio'
p 'converted value is', seconds * (ARGV[1] ||29.97/30).to_f
p 'another converted value is', seconds* (ARGV[2] ||29.97/30).to_f
