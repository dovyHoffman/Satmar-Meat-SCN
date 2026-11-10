-- READ ONLY diagnostic: what is using the disk
select 'stmt' as k, left(regexp_replace(query,'\s+',' ','g'),110) as q, calls, round(total_exec_time::numeric/1000) as total_s, shared_blks_read as blks_read, shared_blks_hit as blks_hit, rows
from pg_stat_statements order by shared_blks_read desc limit 12;
