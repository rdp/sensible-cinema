--run with recreate.sh
CREATE TABLE URL(
   ID INT PRIMARY KEY     NOT NULL,
   URL           TEXT    NOT NULL,
   name          TEXT     NOT NULL, -- CHAR(50)
   SALARY         REAL
);
create index url_url_index on URL(URL); 

CREATE TABLE EDITS (
   ID INT PRIMARY KEY     NOT NULL,
   START          REAL,
   END            REAL,
   CATEGORY       TEXT NOT NULL, -- deity or violence
   SUBCATEGORY    TEXT NOT NULL, -- gore-3
   DETAILS        TEXT NOT NULL, -- gosh what is going on? LOL
   URL_ID         INT, FOREIGN KEY(URL_ID) REFERENCES URL(ID)
);

