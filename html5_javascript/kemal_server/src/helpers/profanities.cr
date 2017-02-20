# warning: somewhat scary/explicit down there!










































    # OK the types are basically
    # full -> category, sanitized
    # partial -> category, sanitized
    # want in end "bad" => ["sanitized", :partial_word, "category ex deity"]
    # some "lesser" too ai ai...
    Arse = "a" +
      "s"*2
    Bad_full_word_profanities_with_sanitized_and_category = 
    {"hell" => ["h***", "h***"],
      Arse => ["a**", "a**"],
      "dieu" => ["deity", "deity omg"],
      "chri" +
      "st"=> ["___", "deity omg"],
      "cock" => ["....", "bodily part reference harsh"]
    }

    Bad_partial_profanities_with_sanitized_and_category =
      { "g" +
      111.chr + 
      100.chr +
      "s" => ["deitys", "deity"],
      "g" +
      111.chr + 
      100.chr => ["___", "deity"],  # get aggressive with this one
      "meu deus" => ["___", "deity omg"],
      "lo" + 
      "rd" => ["l...", "deity omg"],
      "da" +
      "mn" => ["d***", "d***"],
      "f" +
      117.chr +
      99.chr +
      107.chr => ["f***", "f***"], 
      "allah" => ["all..", "deity omg"],
      "bi" +
      "tc" + 104.chr => ["b****", "personal insult harsh"],
      "bas" +
      "ta" + 
      "r" + 100.chr => ["ba.....", "personal insult harsh"],
      # unfortunately there are too many words like assistant so can't just do a**
      Arse + "h" +
      "ole" => ["a..h...", "a**"],
      Arse + "w" +
      "ipe" => ["a..w...", "a**"],
      "jes" +
      "u" + "s" => ["___", "deity"],
      "sh" +
       "i" + "t" => ["s***", "s***"],
      "cu" +
      "nt" => ["c...", "bodily part reference harsh"]
    }
        
    Semi_bad_profanities = 
    { "moron" => "personal insult minor",
      "breast" => "bodily part reference minor",
      "idiot" => "personal insult minor",
      "sex" => "sexual reference",
      "genital" => "bodily part reference minor",
      "bloody" => "minor expletive",
      "boob" => "bodily part reference minor",
      "naked" => "bodily part reference minor",
      "tits" => "bodily part reference minor",
      "make love" => "sexual reference",
      "pen" +
      "is" => "bodily part reference harsh",
      "pu" +
      "ssy" => "bodily part reference harsh",
      "gosh" => "euphemized",
      "whore" => "personal insult harsh",
      "debauch" => "sexual reference",
      "come to bed" => "sexual reference",
      "lie with" => "sexual reference",
      "making love" => "sexual reference",
      "love mak" => "sexual reference",
      "dumb" => "personal insult minor",
      "suck" => "bodily part reference minor",
      "piss" => "bathroom humor",
      "d" + "ick"=> "bodily part reference harsh",
       "v" +
       "ag" +
       "i" + 
       "na" => "bodily part reference harsh",
       "int" +
       "er" +
       "cour" +
       "se" => "sexual reference",
       "panties" => "bodily part reference minor",
       "dumb" => "personal insult minor",
       "fart" => "bodily part reference minor"
	  }.map{ |name, category|
      {bad_word: name, sanitized: name, type: :partial, category: category} # no sanitized deemed needed uh guess
    }
	
   {"butt" => "bodily part reference minor", "crap" => "euphemized"}.each{|bad_word, category| # avoid scrap, butter
    Semi_bad_profanities << {bad_word: bad_word, type: :full_word_only, category: category, sanitized: bad_word}    
   }

  Bad_profanities = Bad_full_word_profanities_with_sanitized_and_category.map{|bad_word, sanitized_and_category|
    {bad_word: bad_word, type: :full_word_only, category: sanitized_and_category[1], sanitized: sanitized_and_category[0] }
  }
  Bad_partial_profanities_with_sanitized_and_category.each{ |bad_word, sanitized_and_category|
    Bad_profanities << {bad_word: bad_word, type: :partial, category: sanitized_and_category[1], sanitized: sanitized_and_category[0] }
  }