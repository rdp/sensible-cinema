drop table if exists edits;
drop table if exists urls;
CREATE TABLE urls (
   id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   url VARCHAR(1024)              NOT NULL DEFAULT '',
   name          VARCHAR(1024)    NOT NULL DEFAULT '',
   editing_notes VARCHAR(1024)    NOT NULL DEFAULT '', -- no default specified and we're hosed  with future column name changes :|
--   imdb_url      VARCHAR(1024)    NOT NULL, -- can't use their ratings I doubt :|
--   trailer_urls  VARCHAR(1024)    NOT NULL,
--   synopsis      VARCHAR(1024)    NOT NULL
   age_recommendation_after_edited INT NOT NULL DEFAULT 0,
   wholesome_uplifting_level INT   NOT NULL DEFAULT 0,
   good_movie_rating INT NOT NULL DEFAULT 0, -- our rating out of 10
   review VARCHAR(8192) NOT NULL DEFAULT '', -- our rating explanation, age recommendation explanation :)
   amazon_episode_number INTEGER NOT NULL DEFAULT 0,
   amazon_episode_name VARCHAR(1024) NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX url_episode_num ON urls(url(256), amazon_episode_number); -- for unique *and* lookups (256 to avoid some mysql index too long)

CREATE TABLE edits (
   id             INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   start          REAL NOT NULL,
   endy           REAL NOT NULL,
   category       VARCHAR(1024) NOT NULL, 
   subcategory    VARCHAR(1024) NOT NULL, 
   details        VARCHAR(1024) NOT NULL, 
   more_details   VARCHAR(1024) NOT NULL, 
   default_action VARCHAR(1024) NOT NULL, 
   url_id         INT NOT NULL, FOREIGN KEY(URL_ID) REFERENCES urls(id)
);

insert into urls (url, name, editing_notes, amazon_episode_number, amazon_episode_name, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, review) 
   values ("https://www.netflix.com/watch/80016225", 'dunno name', "not done yet2", 0, "", 10, 8, 4, "review");
insert into urls (url, name, editing_notes, amazon_episode_number, amazon_episode_name, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, review) 
   values ("https://www.netflix.com/watch/80016224", 'meet the mormons [test]', "not done yet", 0, "", 10, 8, 4, "review");

insert into edits (start, endy, category, subcategory, details, default_action, url_id, more_details) values
      (2.0, 7.0, "a category", "a subcat", "details", "skip", (select id from urls where url='https://www.netflix.com/watch/80016224'), "");
insert into edits (start, endy, category, subcategory, details, default_action, url_id, more_details) values
      (10.0, 30.0, "a category", "a subcat", "details", "mute", (select id from urls where url='https://www.netflix.com/watch/80016224'), "");

alter table urls ADD COLUMN details VARCHAR(1024) NOT NULL DEFAULT '';
alter table urls CHANGE editing_notes editing_status VARCHAR(1024);

--

alter table urls ADD COLUMN image_url VARCHAR(2014) NOT NULL DEFAULT '';

-- output some to screen
select * from urls;
select * from edits;
