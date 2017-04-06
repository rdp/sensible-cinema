Subcats = {} of String => String
# if you change anything in this file be careful that any auto scan subs need to match it [you can tell by doing a single upload]
def subcategory_map
   # I guess this is like "end consumer friendly" and "creator instructions" the double dash is needed
   
   if (Subcats.size == 0)  # I couldn't resist though probably unneeded LOL
   Subcats.merge!({
    "initial theme song" => "movie-content -- initial theme song/credits",
    "closing credits" => "movie-content -- closing credits/songs",
    "joke edit" => "movie-content -- joke edit -- edits that make it funny when applied",
    "movie content morally questionable choice" => "movie-content -- morally questionable choice",
    "movie content other" => "movie-content -- other",

    "loud noise" => "profanity -- loud noise/screaming",
    "personal insult mild" => "profanity -- insult (\"moron\", \"idiot\" etc.)",
    "personal insult harsh" => "profanity -- insult harsh (b.... etc.)",
    "personal attack mild" => "profanity -- attack command (\"shut up\" etc.)",
    "being mean" => "profanity -- being mean/cruel to another",
    "crude humor" => "profanity -- crude humor, like poop, bathroom, gross, etc.",
    "bodily part reference mild" => "profanity -- bodily part reference mild (butt, bumm...)",
    "bodily part reference harsh" => "profanity -- bodily part reference harsh",
    "sexual reference" => "profanity -- sexual innuendo/reference",
    "euphemized profanities" => "profanity -- euphemized worser profanities (ex: crap, dang, gosh)",
    "lesser expletive" => "profanity -- other lesser expletive ex \"bloomin'\" etc.",
    "deity religious context" => "profanity -- deity use in religious context like \"the l... is good\"",
    "deity exclamation mild" => "profanity -- deity exclamation mild like Good L...,",
    "deity greek" => "profanity -- deity greek (Zeus, etc.)",
    "deity foreign language" => "profanity -- deity different language, like Allah or French equivalents, etc",
    "deity exclamation harsh" => "profanity -- deity exclamation harsh, name of the Lord (omg, etc.)",
    "deity expletive" => "profanity -- deity expletive (es: goll durn, the real words)",
    "a word" => "profanity -- a.. (and/or followed by anything)",
    "d word" => "profanity -- d word",
    "h word" => "profanity -- h word",
    "s word" => "profanity -- s word",
    "f word" => "profanity -- f-bomb expletive",
    "f word sex connotation" => "profanity -- f-bomb sexual connotation",
    "profanity (other)" => "profanity -- other",
		
    "crudeness" => "violence -- crude humor, grossness, vulgar, etc.",
    "stabbing/shooting no blood" => "violence -- stabbing/shooting no blood",
    "stabbing/shooting with blood" => "violence -- stabbing/shooting yes blood",
    "visible blood" => "violence -- visible blood of wound",
    "open wounds" => "violence -- gore/open wound",
    "light fight" => "violence -- light fighting (single punch/kick/hit/push)",
    "comedic fight" => "violence -- comedic/slapstick fighting",
    "sustained fight" => "violence -- sustained punching/fighting",
    "killing" => "violence -- killing on screen (ex: bullet shot)",
    "killing offscreen" => "violence -- killing off screen",
    "circumstantial death" => "violence -- death non-killing, like falling",
    "threatening actions" => "violence -- threatening actions",
    "rape" => "violence -- rape",
    "violence (other)" => "violence -- other",

    "art nudity" => "physical -- art based nudity",
    "revealing clothing" => "physical -- revealing clothing (scantily clad)",
    "revealing cleavage" => "physical -- revealing clothing (cleavage)",
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

    "alcohol" => "substance-abuse -- alcohol drinking",
    "smoking" => "substance-abuse -- smoking legal stuff (cigar, cigarette)",
    "smoking illegal" => "substance-abuse -- smoking illegal drugs",
    "drugs" => "substance-abuse -- illegal drug use",
    "drug injection" => "substance-abuse -- drug use injection",
    "substance-abuse other" => "substance-abuse -- other",

    "frightening/startling scene/event" => "suspense -- frightening/startling scene/event",
    "suspenseful fight \"will they win?\"" => "suspense -- suspenseful fight \"will they win?\"",
    "suspense other" => "suspense -- other",
    })
  end
  Subcats
end
