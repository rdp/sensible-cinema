alter table urls add amazon_episode_name      TEXT   NOT NULL DEFAULT "";

-- guess I didn't have any unique url constraint before this, only id...
CREATE UNIQUE INDEX url_episode ON urls(url, amazon_episode_name);

select * from urls;
select * from edits;
