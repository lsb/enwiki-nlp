create table words (id integer primary key not null, word varchar(50));
create table corpus_words (id integer primary key not null, article_id integer, word_id integer);
pragma default_cache_size = 31000000;
