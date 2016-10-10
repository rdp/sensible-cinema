--run with recreate.sh

CREATE TABLE URLS (
   id INTEGER PRIMARY KEY,
   url           TEXT    UNIQUE NOT NULL,
   name          TEXT    NOT NULL,
);
create index url_url_index on URLS(URL); 
  
CREATE TABLE EDITS (
   id             INTEGER PRIMARY KEY,
   start          REAL NOT NULL,
   endy           REAL NOT NULL,
   category       TEXT NOT NULL, 
   subcategory    TEXT NOT NULL, 
   subcategory_level    INT  NOT NULL, 
   details        TEXT NOT NULL, 
   default_action TEXT NOT NULL, 
   url_id         INT, FOREIGN KEY(URL_ID) REFERENCES URLS(ID)
);

insert into urls (url, name) values ("http://url", 'a_name";alert("xss");"'); -- no ID needed
insert into edits (start, endy, category, subcategory, subcategory_level, details, default_action, url_id) values
    (20090.50, 20100.50, "a category", "a subcat", 3, "details", "mute", last_insert_rowid());
-- output some to screen

insert into urls (url, name) values ("https://www.netflix.com/watch/80016224", 'meet the mormons [test]');
insert into edits (start, endy, category, subcategory, subcategory_level, details, default_action, url_id) values
      (2.0, 7.0, "a category", "a subcat", 3, "details", "skip", (select id from urls where url='https://www.netflix.com/watch/80016224'));
insert into edits (start, endy, category, subcategory, subcategory_level, details, default_action, url_id) values
          (10.0, 30.0, "a category", "a subcat", 3, "details", "mute", (select id from urls where url='https://www.netflix.com/watch/80016224'));


select * from urls;
select * from edits;

alter table urls add episode_name      TEXT   NOT NULL;
