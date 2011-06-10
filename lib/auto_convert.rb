seconds = eval(ARGV[0] || "1000").to_f
p 'syntax: second to convert, first conversion ratio, second conversation ratio'
twentyNinePointNineSeven =  30000/1001.0
p 'converted value is', seconds * (ARGV[1] || twentyNinePointNineSeven/30).to_f
p 'another converted value is', seconds* (ARGV[2] || 30/twentyNinePointNineSeven).to_f
