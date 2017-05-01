-- reverse order here
drop table if exists tag_edit_list_to_tag;
drop table if exists tag_edit_list;
drop table if exists tags;
drop table if exists urls;
drop table if exists users;

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
   values ("https:&#x2F;&#x2F;www.amazon.com&#x2F;Avatar-Last-Airbender-Season-3&#x2F;dp&#x2F;B001J6GZXK", 'ALTA season 3', "this does not have real edits", 5, "Beach test", 10, 8, 4, "review");
insert into urls (url, name, editing_notes, amazon_episode_number, amazon_episode_name, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, review) 
   values ("https://localhost:3000/test_movie_for_practicing_edits.html", 'big buck bunny localhost', "not done yet", 0, "", 10, 8, 4, "review");
insert into urls (url, name, editing_notes, amazon_episode_number, amazon_episode_name, age_recommendation_after_edited, wholesome_uplifting_level, good_movie_rating, review) 
   values ("https://playitmyway.org/test_movie_for_practicing_edits.html", 'big buck bunny pimw', "not done yet", 0, "", 10, 8, 4, "review");

insert into edits (start, endy, category, subcategory, details, default_action, url_id, more_details) values
      (2.0, 7.0, "a category", "a subcat", "details", "skip", (select id from urls where url='https:&#x2F;&#x2F;www.amazon.com&#x2F;Avatar-Last-Airbender-Season-3&#x2F;dp&#x2F;B001J6GZXK'), "");
insert into edits (start, endy, category, subcategory, details, default_action, url_id, more_details) values
      (10.0, 20.0, "a category", "a subcat", "details", "mute", (select id from urls where url='https:&#x2F;&#x2F;www.amazon.com&#x2F;Avatar-Last-Airbender-Season-3&#x2F;dp&#x2F;B001J6GZXK'), "");

alter table urls ADD COLUMN details VARCHAR(1024) NOT NULL DEFAULT '';
alter table urls CHANGE editing_notes editing_status VARCHAR(1024);
update urls set editing_status = 'Done with second review, tags viewed as complete';

--

alter table urls ADD COLUMN image_url VARCHAR(2014) NOT NULL DEFAULT '';
update urls set image_url = 'https://upload.wikimedia.org/wikipedia/en/b/ba/Airbender-CompleteBook3.jpg' where id = 1; -- test data :)
alter table urls ADD COLUMN is_amazon_prime INT NOT NULL DEFAULT 0; -- probably should be TINYINT(1) but crystal mysql adapter no support it [?]
alter table urls ADD COLUMN rental_cost DECIMAL NOT NULL DEFAULT 0.0; -- too scared to use floats
update urls set rental_cost = -1 where id = 1; -- freebie
alter table urls ADD COLUMN purchase_cost DECIMAL NOT NULL DEFAULT 0.0;

alter table urls ADD COLUMN total_time REAL NOT NULL default 0.0;

alter table urls ADD COLUMN amazon_second_url VARCHAR(2014) NOT NULL DEFAULT '';
CREATE INDEX url_amazon_second_url_episode_idx ON urls(amazon_second_url(256), amazon_episode_number); -- non unique on purpose XXX do queries use this?

create unique index url_title_episode ON urls(name(256), amazon_episode_number); -- try to avoid accidental dupes
ALTER TABLE urls DROP INDEX url_title_episode; 
CREATE UNIQUE INDEX unique_name_with_episode ON urls(name(256), amazon_episode_number); -- rename same index

ALTER TABLE urls CHANGE amazon_episode_name episode_name VARCHAR(1024);
ALTER TABLE urls CHANGE amazon_episode_number episode_number INTEGER;

alter table urls add column amazon_prime_free_type VARCHAR(2014) NOT NULL DEFAULT '';
update urls set amazon_prime_free_type = 'Prime' where is_amazon_prime = 1;
alter table urls drop column is_amazon_prime;

RENAME TABLE edits TO tags; 

CREATE TABLE tag_edit_list (
   id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   url_id INT NOT NULL,
   description          VARCHAR(1024)    NOT NULL DEFAULT '',
   notes VARCHAR(1024)    NOT NULL DEFAULT '',
   age_recommendation_after_edited INT NOT NULL DEFAULT 0,
	  FOREIGN KEY(URL_ID) REFERENCES urls(id)
   -- "community" :)
);

ALTER TABLE urls drop column age_recommendation_after_edited;

CREATE TABLE tag_edit_list_to_tag (
   id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   tag_edit_list_id INT NOT NULL, FOREIGN KEY(tag_edit_list_id) references tag_edit_list(id),
   tag_id INT NOT NULL, FOREIGN KEY (tag_id) references tags(id),
   action VARCHAR(1024) NOT NULL
);
-- TODO some indices for these?

alter table tag_edit_list change notes status_notes VARCHAR(1024)    NOT NULL DEFAULT '';

-- XXX rename all tables to singular... :)

alter table urls add column create_timestamp TIMESTAMP not null DEFAULT NOW();

ALTER TABLE `urls` CHANGE COLUMN `image_url` `image_local_filename` VARCHAR(2014) NOT NULL DEFAULT '';
update urls set image_local_filename = '1_maxresdefault.jpg' where id = 1; -- test data :)
update urls set details = 'Aang escapes a killer while the bad guys camp at the beach' where id = 1; -- test data :)

alter table tags add column oval_percentage_coords VARCHAR(24)    NOT NULL DEFAULT '';
alter table tags drop column more_details;
alter table tags change oval_percentage_coords oval_percentage_coords  VARCHAR(100) NOT NULL DEFAULT '';

alter table urls add column subtitles LONGTEXT NOT NULL;

alter table urls add column genre VARCHAR(100) NOT NULL DEFAULT '';
alter table urls add column original_rating VARCHAR(10) NOT NULL DEFAULT '';
alter table tags add column age_maybe_ok INT NOT NULL DEFAULT 0;
alter table urls add column wholesome_review TEXT; -- said my row was too big otherwise :|
update urls set wholesome_review = ''; -- default for existing :|
alter table urls add column count_downloads INT NOT NULL DEFAULT 0;
alter table tags drop column oval_percentage_coords;
alter table urls add column editing_notes TEXT;
update urls set editing_notes = ''; -- default for existing :|
alter table urls add column community_contrib BOOL DEFAULT true; -- actually 0 or 1 apparently
-- done prod

CREATE TABLE users (
   id             INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   name       VARCHAR(2048) NOT NULL, 
   email    VARCHAR(512) NOT NULL, 
   user_id        VARCHAR(128) NOT NULL, 
   type  VARCHAR(1024) NOT NULL
);
ALTER TABLE users ADD CONSTRAINT unique_email_user_id UNIQUE (email, user_id);
insert into users values (0, "test_user_name", "test@test.com", "test_user_id", "facebook");

alter table tag_edit_list add column user_id INT NOT NULL DEFAULT 0;
alter table tags add column impact_to_movie INT NOT NULL DEFAULT 0; -- assume 1 means "some" :)

alter table urls add rental_cost_sd DECIMAL(10, 2) NOT NULL DEFAULT 0;
alter table urls add purchase_cost_sd DECIMAL(10, 2) NOT NULL DEFAULT 0;

alter table urls modify rental_cost DECIMAL(10, 2); -- turns out DECIMAL by default is truncated :|
alter table urls modify purchase_cost DECIMAL(10, 2);

ALTER TABLE users DROP INDEX unique_email_user_id;
-- just pretend that once an email is in there, you're stuck with it...so I can combine them later if people login'ish up front [?]
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);
alter table users add column email_subscribe BOOL DEFAULT false; -- actually 0 or 1 apparently
alter table users add column editor BOOL DEFAULT false; -- actually 0 or 1 apparently
alter table users add column admin BOOL DEFAULT false; -- actually 0 or 1 apparently

alter table urls ADD COLUMN amazon_third_url VARCHAR(2014) NOT NULL DEFAULT '';
CREATE INDEX url_amazon_third_url_episode_idx  ON urls(amazon_third_url(256), episode_number); -- non unique on purpose XXX do queries use this?

-- and output to screen to show success...
select * from urls;
select * from tags;

