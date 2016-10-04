--run with recreate.sh

CREATE TABLE URLS (
   id INTEGER PRIMARY KEY,
   url           TEXT    UNIQUE NOT NULL,
   name          TEXT    NOT NULL -- CHAR(50) REAL
);
create index url_url_index on URLS(URL); 
  
CREATE TABLE EDITS (
   id             INTEGER PRIMARY KEY,
   start          REAL NOT NULL,
   endy           REAL NOT NULL,
   category       TEXT NOT NULL, -- profanity or violence
   subcategory    TEXT NOT NULL, -- deity or gore
   subcategory_level    INT  NOT NULL, -- 3 out of 10
   details        TEXT NOT NULL, -- **** what is going on? said sally
   default_action TEXT NOT NULL, -- skip, mute, almost mute, no-video-yes-audio
   url_id         INT, FOREIGN KEY(URL_ID) REFERENCES URLS(ID)
);

insert into urls (url, name) values ("http://url", "a_name"); -- no ID needed
insert into edits (start, endy, category, subcategory, subcategory_level, details, default_action, url_id) values
    (20090.50, 20100.50, "a category", "a subcat", 3, "details", "def action", last_insert_rowid());
-- output some to screen
select * from urls;
select * from edits;