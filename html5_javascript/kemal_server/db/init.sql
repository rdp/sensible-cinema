--run with recreate.sh script...

CREATE TABLE URLS (
   id INTEGER PRIMARY KEY,
   url           TEXT    NOT NULL,
   name          TEXT    NOT NULL,
   editing_notes TEXT    NOT NULL,
--   imdb_url      TEXT    NOT NULL, -- can't use their ratings I doubt :|
--   trailer_urls  TEXT    NOT NULL,
--   synopsis      TEXT    NOT NULL
   age_recommendation_after_edited INT NOT NULL,
   uplifting_level INT   NOT NULL, -- out of 10 wholesome as well?
   overall_rating INT NOT NULL, -- our rating out of 10
   review TEXT NOT NULL, -- our rating explanation :)
   amazon_episode_number INTEGER NOT NULL,
   amazon_episode_name TEXT NOT NULL
);

CREATE UNIQUE INDEX url_episode_num ON urls(url, amazon_episode_number); -- for unique *and* index

CREATE TABLE EDITS (
   id             INTEGER PRIMARY KEY,
   start          REAL NOT NULL,
   endy           REAL NOT NULL,
   category       TEXT NOT NULL, 
   subcategory    TEXT NOT NULL, 
   details        TEXT NOT NULL, 
   more_details        TEXT NOT NULL, 
   default_action TEXT NOT NULL, 
   url_id         INT, FOREIGN KEY(URL_ID) REFERENCES URLS(ID)
);

insert into urls (url, name, editing_notes, amazon_episode_number, amazon_episode_name, age_recommendation_after_edited, uplifting_level, overall_rating, review) 
   values ("https://www.netflix.com/watch/80016224", 'meet the mormons [test]', "not done yet", 0, "", 10, 8, 4, "review");
insert into edits (start, endy, category, subcategory, details, default_action, url_id, more_details) values
      (2.0, 7.0, "a category", "a subcat", "details", "skip", (select id from urls where url='https://www.netflix.com/watch/80016224'), "");
insert into edits (start, endy, category, subcategory, details, default_action, url_id, more_details) values
      (10.0, 30.0, "a category", "a subcat", "details", "mute", (select id from urls where url='https://www.netflix.com/watch/80016224'), "");

-- output some to screen
select * from urls;
select * from edits;
