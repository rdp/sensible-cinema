--run with recreate.sh

CREATE TABLE URLS(
   id INTEGER PRIMARY KEY,
   URL           TEXT    UNIQUE NOT NULL,
   NAME          TEXT    NOT NULL -- CHAR(50) REAL
);
create index url_url_index on URLS(URL); 
  
CREATE TABLE EDITS (
   id INTEGER PRIMARY KEY,
   START          REAL NOT NULL,
   ENDY           REAL NOT NULL,
   CATEGORY       TEXT NOT NULL, -- profanity or violence
   SUBCATEGORY    TEXT NOT NULL, -- deity or gore
   SUBCATEGORY_LEVEL    INT  NOT NULL, -- 3 out of 10
   DETAILS        TEXT NOT NULL, -- **** what is going on? said sally
   DEFAULT_ACTION TEXT NOT NULL, -- skip, mute, almost mute, no-video-yes-audio
   URL_ID         INT, FOREIGN KEY(URL_ID) REFERENCES URLS(ID)
);

insert into urls (url, name) values ("http://url", "a_name"); -- no ID needed
insert into edits (start, endy, category, subcategory, details, url_id) values
    (20090.50, 20100.50, "a category", "a subcat", "details", last_insert_rowid());
-- output some to screen
select * from urls;
select * from edits;