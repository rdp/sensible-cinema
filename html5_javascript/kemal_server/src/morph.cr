require "./src/helpers/*"

puts Tag.all.select{|t| t.details =~ /'/}.each{|t| t.details = t.details.gsub("'", "&#x27;"); puts t.details; t.save}
