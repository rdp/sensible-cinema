--run with recreate.sh

CREATE TABLE URLS(
   ID INT PRIMARY KEY,
   URL           TEXT    UNIQUE NOT NULL,
   NAME          TEXT    NOT NULL -- CHAR(50) REAL
);
create index url_url_index on URLS(URL); 
  
CREATE TABLE EDITS (
   ID INT PRIMARY KEY,
   START          REAL,
   ENDY            REAL,
   CATEGORY       TEXT NOT NULL, -- deity or violence
   SUBCATEGORY    TEXT NOT NULL, -- gore-3
   DETAILS        TEXT NOT NULL, -- gosh what is going on? LOL
   URL_ID         INT, FOREIGN KEY(URL_ID) REFERENCES URLS(ID)
);

insert into urls (url, name) values ("http://url", "a_name"); -- no ID needed
insert into edits (start, endy, category, subcategory, details, url_id) values
    (20090.50, 20100.50, "a category", "a subcat", "details", last_insert_rowid());