# warning: somewhat scary/explicit down there!








































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
      "dieu" => ["deity", "deity foreign language"],
      "chri" +
      "st"=> ["___", "deity exclamation harsh"],
      "cock" => ["....", "bodily part reference harsh"],
      "jove" => ["jove", "deity greek"],
      "beaner" => ["beaner", "derogatory slur"],
      "homo" => ["homo", "derogatory slur"],
      "prick" => ["prick", "being mean"],
      "faggot" => ["faggot", "derogatory slur"]
    }

    Bad_partial_profanities_with_sanitized_and_category =
      { "g" +
      111.chr + 
      100.chr +
      "s" => ["deitys", "deity greek"],
      "g" +
      111.chr + 
      100.chr => ["___", "deity exclamation harsh"],
      "meu deus" => ["___", "deity foreign language"],
      "lo" + 
      "rd" => ["l...", "deity exclamation mild"], # there are things like "fire lord" that aren't harsh...
      "da" +
      "mn" => ["d...", "d word"],
      "f" +
      117.chr +
      99.chr +
      107.chr => ["____", "f word"], 
      "allah" => ["all..", "deity foreign language"],
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
      "u" + "s" => ["___", "deity exclamation harsh"],
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
      "bloody" => "lesser expletive",
      "bloomin" => "lesser expletive",
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
