CREATE TABLE URLS (
   id INTEGER PRIMARY KEY,
   url           TEXT    NOT NULL DEFAULT '',
   name          TEXT    NOT NULL DEFAULT '',
   editing_notes TEXT    NOT NULL DEFAULT '', -- no default specified and we're hosed  with future column name changes :|
--   imdb_url      TEXT    NOT NULL, -- can't use their ratings I doubt :|
--   trailer_urls  TEXT    NOT NULL,
--   synopsis      TEXT    NOT NULL
   age_recommendation_after_edited INT NOT NULL DEFAULT 0,
   wholesome_uplifting_level INT   NOT NULL DEFAULT 0,
   good_movie_rating INT NOT NULL DEFAULT 0, -- our rating out of 10
   review TEXT NOT NULL DEFAULT '', -- our rating explanation, age recommendation explanation :)
   amazon_episode_number INTEGER NOT NULL DEFAULT 0,
   amazon_episode_name TEXT NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX url_episode_num ON urls(url, amazon_episode_number); -- for unique *and* lookups

CREATE TABLE EDITS (
   id             INTEGER PRIMARY KEY,
   start          REAL NOT NULL,
   endy           REAL NOT NULL,
   category       TEXT NOT NULL, 
   subcategory    TEXT NOT NULL, 
   details        TEXT NOT NULL, 
   more_details   TEXT NOT NULL, 
   default_action TEXT NOT NULL, 
   url_id         INT, FOREIGN KEY(URL_ID) REFERENCES URLS(ID)
);

insert into urls (url, name, editing_notes, amazon_episode_number, amazon_episode_name, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, review) 
   values ("https://www.netflix.com/watch/80016225", 'dunno name', "not done yet2", 0, "", 10, 8, 4, "review");
insert into urls (url, name, editing_notes, amazon_episode_number, amazon_episode_name, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, review) 
   values ("https://www.netflix.com/watch/80016224", 'meet the mormons [test]', "not done yet", 0, "", 10, 8, 4, "review");

insert into edits (start, endy, category, subcategory, details, default_action, url_id, more_details) values
      (2.0, 7.0, "a category", "a subcat", "details", "skip", (select id from urls where url='https://www.netflix.com/watch/80016224'), "");
insert into edits (start, endy, category, subcategory, details, default_action, url_id, more_details) values
      (10.0, 30.0, "a category", "a subcat", "details", "mute", (select id from urls where url='https://www.netflix.com/watch/80016224'), "");

alter table URLS ADD COLUMN details TEXT NOT NULL DEFAULT '';
-- editing_notes -> editing_status :|
alter table URLS ADD COLUMN editing_status TEXT NOT NULL DEFAULT '';
update urls set editing_status = editing_notes;
update urls set editing_notes = ''; -- abandon old column

-- output some to screen
select * from urls;
select * from edits;
