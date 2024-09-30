


-- Create the initial table
create table dont_drop_me(col1 varchar, col2 varchar)
;

-- Insert 4 rows of some sample data
insert overwrite into dont_drop_me values
('col1_row1', 'col2_row1'),
('col1_row2', 'col2_row2'),
('col1_row3', 'col2_row3'),
('col1_row4', 'col2_row4')
;

-- Replace the table (by accident?). New table has an extra column to prove changes.
create or replace table dont_drop_me(col1 varchar, col2 varchar, col3 varchar);

-- Now the new table contains no data but has 1 extra column
select * from dont_drop_me;
-- +----+----+----+
-- |COL1|COL2|COL3|
-- +----+----+----+

-- View what tables are on the history. The top row is the current table, the second
-- row is the first table that we replaced
show tables history like 'dont_drop_me';
-- +------------------------------+------------+-------------+-----------+-----+-------+----------+----+-----+--------+--------------+------------------------------+--------------------+---------------+-------------------+----------------------------+-------------------------+-----------+
-- |created_on                    |name        |database_name|schema_name|kind |comment|cluster_by|rows|bytes|owner   |retention_time|dropped_on                    |automatic_clustering|change_tracking|search_optimization|search_optimization_progress|search_optimization_bytes|is_external|
-- +------------------------------+------------+-------------+-----------+-----+-------+----------+----+-----+--------+--------------+------------------------------+--------------------+---------------+-------------------+----------------------------+-------------------------+-----------+
-- |2021-02-26 04:56:23.948 -08:00|DONT_DROP_ME|SIMON_DB     |PUBLIC     |TABLE|       |          |0   |0    |SYSADMIN|1             |NULL                          |OFF                 |OFF            |OFF                |NULL                        |NULL                     |N          |
-- |2021-02-26 04:56:19.610 -08:00|DONT_DROP_ME|SIMON_DB     |PUBLIC     |TABLE|       |          |4   |1024 |SYSADMIN|1             |2021-02-26 04:56:24.073 -08:00|OFF                 |OFF            |OFF                |NULL                        |NULL                     |N          |
-- +------------------------------+------------+-------------+-----------+-----+-------+----------+----+-----+--------+--------------+------------------------------+--------------------+---------------+-------------------+----------------------------+-------------------------+-----------+

-- We need to rename existing object to move it off the top of the stack so that we can recover the first one
alter table dont_drop_me rename to renamed_dont_drop_me;

-- Now view what tables are in the history again. You can see that the first table created has moved to the top of the stack
show tables history like 'dont_drop_me';
-- +------------------------------+------------+-------------+-----------+-----+-------+----------+----+-----+--------+--------------+------------------------------+--------------------+---------------+-------------------+----------------------------+-------------------------+-----------+
-- |created_on                    |name        |database_name|schema_name|kind |comment|cluster_by|rows|bytes|owner   |retention_time|dropped_on                    |automatic_clustering|change_tracking|search_optimization|search_optimization_progress|search_optimization_bytes|is_external|
-- +------------------------------+------------+-------------+-----------+-----+-------+----------+----+-----+--------+--------------+------------------------------+--------------------+---------------+-------------------+----------------------------+-------------------------+-----------+
-- |2021-02-26 04:56:19.610 -08:00|DONT_DROP_ME|SIMON_DB     |PUBLIC     |TABLE|       |          |4   |1024 |SYSADMIN|1             |2021-02-26 04:56:24.073 -08:00|OFF                 |OFF            |OFF                |NULL                        |NULL                     |N          |
-- +------------------------------+------------+-------------+-----------+-----+-------+----------+----+-----+--------+--------------+------------------------------+--------------------+---------------+-------------------+----------------------------+-------------------------+-----------+

-- Now undrop the table and prove that it is the old one (the one with 4 rows and 2 columns)
undrop table dont_drop_me;
select * from dont_drop_me;
-- +---------+---------+
-- |COL1     |COL2     |
-- +---------+---------+
-- |col1_row1|col2_row1|
-- |col1_row2|col2_row2|
-- |col1_row3|col2_row3|
-- |col1_row4|col2_row4|
-- +---------+---------+
Share
Improve this answer
Follow
edited Jun 14 at 8:01
answered Feb 26, 2021 at 15:41
Simon D's user avatar
Simon D
6,02222 gold badges1919 silver badges3636 bronze badges
1
I would also add, that undrop works like a stack. So if you run "create or replace table" a couple of times, you would have to undrop several times. – 
Yaron Levi
 CommentedSep 22, 2022 at 5:31
1
Awesome life-saver! ++1! – 
neverMind
 CommentedFeb 28 at 19:02
Add a comment

Report this ad
2

This assumes you have the required time travel enabled/available...

Clone the table at the required point in time
Rename the table to anything you want
Rename the clone to the original table name
Cloning at a point in time is described here: Cloning Time Travel

Share
Improve this answer
Follow
answered Feb 26, 2021 at 13:58
NickW's user avatar
NickW
9,48622 gold badges88 silver badges2121 bronze badges
Add a comment
1

The UNDROP TABLE would do the trick but because you've run a CREATE OR REPLACE, you will first have to move the newly created table into a different schema:

For example:

use database dev;

create table public.t1 (id int);
insert into public.t1 (id) values (1), (2);

create or replace table public.t1 (id int);

create schema temp_schema;

alter table public.t1 rename to temp_schema.t1;

undrop table public.t1;