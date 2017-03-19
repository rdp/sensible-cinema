# warning: somewhat scary/explicit down there!




Subcats = {} of String => String

def subcategory_map
   # I guess this is like "end consumer friendly" and "creator instructions" the double dash is needed
   
   if (Subcats.size == 0)  # I couldn't resist though probably unneeded LOL
   Subcats.merge!({
    "initial theme song" => "movie-content -- initial song/initial credits",
    "closing credits" => "movie-content -- closing credits",
    "song instance" => "movie-content -- song occurrence",
    "joke edit" => "movie-content -- joke edit -- edits that make it funny when edited",
    "movie content other" => "movie-content -- other",
		
    "personal insult mild" => "profanity -- insult (\"moron\", \"idiot\" etc.)",
    "personal insult harsh" => "profanity -- insult harsh (b.... etc.)",
    "personal attack mild" => "profanity -- attack command (\"shut up\" etc.)",
    "crude humor" => "profanity -- crude humor, like poop, bathroom, gross, etc.",
    "bodily part reference mild" => "profanity -- bodily part reference mild (butt, bumm...)",
    "bodily part reference harsh" => "profanity -- bodily part reference harsh",
    "sexual reference" => "profanity -- sexual innuendo/reference",
    "euphemized profanities" => "profanity -- euphemized 4-letter (crap, dang, gosh)",
    "deity appropriate context" => "profanity -- deity use in appropriate context like \"the l... is good\"",
    "deity exclamation mild" => "profanity -- deity exclamation  mildlike Good L...,  the gods, etc.",
    "deity exclamation harsh" => "profanity -- deity exclamation harsh, name of the Lord (omg, etc.)",
    "deity expletive" => "profanity -- deity expletive (es: goll durn but the real words)",
    "mild expletive" => "profanity -- mild expletive ex \"bloomin'\"",
    "a word" => "profanity -- a.. followed by anything else",
    "d word" => "profanity -- d word",
    "h word" => "profanity -- h word",
    "s word" => "profanity -- s word",
    "f word" => "profanity -- f-bomb expletive",
    "f word sex connotation" => "profanity -- f-bomb sexual connotation",
    "profanity (other)" => "profanity -- other",
		
    "stabbing/shooting no blood" => "violence -- stabbing/shooting no blood",
    "stabbing/shooting with blood" => "violence -- stabbing/shooting yes blood",
    "visible blood" => "violence -- visible blood on wound",
    "open wounds" => "violence -- gore/open wound",
    "light fight" => "violence -- light fighting (single punch/kick/hit)",
    "sustained fight" => "violence -- sustained punching/fighting",
    "killing" => "violence -- killing",
    "circumstantial death" => "violence -- death through other means like falls",
    "violence (other)" => "violence -- other",

    "art nudity" => "physical -- art nudity",
    "revealing clothing" => "physical -- revealing clothing (cleavage, scantily clad)",
    "nudity posterior male" => "physical -- nudity (posterior) male",
    "nudity posterior female" => "physical -- nudity (posterior) female",
    "nudity anterior male" => "physical -- nudity (anterior) male",
    "nudity anterior female" => "physical -- nudity (anterior) female",
    "nudity breast" => "physical -- nudity (breast)",
    "kissing peck" => "physical -- kiss (peck)",
    "kissing passionate" => "physical -- kiss (passionate)",
    "sex foreplay" => "physical -- sex foreplay",
    "implied sex" => "physical -- implied sex",
    "explicit sex" => "physical -- explicit sex",
    "physical (other)" => "physical -- other",

    "drugs" => "substance-abuse -- drug use",
    "alcohol" => "substance-abuse -- alcohol drinking",
    "smoking" => "substance-abuse -- smoking",
    "poor moral choice" => "substance-abuse -- any kind of poor moral choice, ex: theft",
    "substance-abuse other" => "substance-abuse -- other"
    })

    # or do they all need this? I mean...visible blood but what *degree* of visible blood?
    ["frightening/startling scene", "suspenseful fight \"will they win?\""].each{ |type|
      ["age 3", "age 6", "age 9", "age 12", "age 16", "(not OK)"].each do |intensity|
        Subcats[type+ " " + intensity] = "suspense -- " + type  + " " + intensity
      end
    }
  end
  Subcats
end






































    # OK the types are basically
    # full -> category, sanitized
    # partial -> category, sanitized
    # want in end "bad" => ["sanitized", :partial_word, "category ex deity"]
    # some "lesser" too ai ai...
    Arse = "a" +
      "s"*2
      
    Bad_beginning_word_profanities_with_sanitized_and_category =
    {
      "hell" => ["h...", "h word"] # avoid shell, catch heckfire, hello also catches unfortunately, misses helicoper though :|
    }
    Bad_full_word_profanities_with_sanitized_and_category = 
    {
      Arse => ["a..", "a word"],
      "dieu" => ["deity", "deity exclamation harsh"],
      "chri" +
      "st"=> ["___", "deity exclamation harsh"],
      "cock" => ["....", "bodily part reference harsh"]
    }

    Bad_partial_profanities_with_sanitized_and_category =
      { "g" +
      111.chr + 
      100.chr +
      "s" => ["deitys", "deity exclamation mild"],
      "g" +
      111.chr + 
      100.chr => ["___", "deity exclamation harsh"],
      "meu deus" => ["___", "deity exclamation harsh"],
      "lo" + 
      "rd" => ["l...", "deity exclamation mild"], # there are things like "fire lord" that aren't harsh...
      "da" +
      "mn" => ["d...", "d word"],
      "f" +
      117.chr +
      99.chr +
      107.chr => ["____", "f word"], 
      "allah" => ["all..", "deity exclamation harsh"],
      "bi" +
      "tc" + 104.chr => ["b....", "personal insult harsh"],
      "bas" +
      "ta" + 
      "r" + 100.chr => ["ba.....", "personal insult harsh"],
      # unfortunately there are too many words like assistant, associate etc. so can't just do "starts with a.." :|
      Arse + "h" +
      "ole" => ["a..h...", "a word"], 
      Arse + "w" +
      "ipe" => ["a..w...", "a word"],
      "jes" +
      "u" + "s" => ["___", "deity exclamation mild"],
      "sh" +
       "i" + "t" => ["s...", "s word"],
      "cu" +
      "nt" => ["c...", "bodily part reference harsh"]
    }
        
    # start with partials, though some don't seem to be...
    Semi_bad_profanities =  
    { "moron" => "personal insult mild",
      "breast" => "bodily part reference mild",
      "idiot" => "personal insult mild",
      "sex" => "sexual reference",
      "genital" => "bodily part reference mild",
      "bloody" => "mild expletive",
      "boob" => "bodily part reference mild",
      "naked" => "bodily part reference mild",
      "tits" => "bodily part reference mild",
      "make love" => "sexual reference",
      "pen" +
      "is" => "bodily part reference harsh",
      "pu" +
      "ssy" => "bodily part reference harsh",
      "gosh" => "euphemized profanities",
      "whore" => "personal insult harsh",
      "debauch" => "sexual reference",
      "come to bed" => "sexual reference",
      "lie with" => "sexual reference",
      "making love" => "sexual reference",
      "love mak" => "sexual reference",
      "dumb" => "personal insult mild",
      "suck" => "bodily part reference mild",
      "piss" => "crude humor",
      "d" + "ick"=> "bodily part reference harsh",
       "v" +
       "ag" +
       "i" + 
       "na" => "bodily part reference harsh",
       "int" +
       "er" +
       "cour" +
       "se" => "sexual reference",
       "panties" => "bodily part reference mild",
       "dumb" => "personal insult mild",
       "fart" => "bodily part reference mild"
	  }.map{ |name, category|
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
      # SemiBadProfanities = this.map
      {bad_word: name, sanitized: name, type: :partial, category: category} # no sanitized deemed needed uh guess
    }
	
   {"butt" => "bodily part reference mild", "crap" => "euphemized profanities"}.each{|bad_word, category| # avoid scrap, butter
    Semi_bad_profanities << {bad_word: bad_word, type: :full_word_only, category: category, sanitized: bad_word}    
   }

  Bad_profanities = Bad_full_word_profanities_with_sanitized_and_category.map{|bad_word, sanitized_and_category|
    {bad_word: bad_word, type: :full_word_only, category: sanitized_and_category[1], sanitized: sanitized_and_category[0] }
  }
  Bad_partial_profanities_with_sanitized_and_category.each{ |bad_word, sanitized_and_category|
    Bad_profanities << {bad_word: bad_word, type: :partial, category: sanitized_and_category[1], sanitized: sanitized_and_category[0] }
  }
  Bad_beginning_word_profanities_with_sanitized_and_category.each{ |bad_word, sanitized_and_category|
    Bad_profanities << {bad_word: bad_word, type: :beginning_word, category: sanitized_and_category[1], sanitized: sanitized_and_category[0] }
  }
