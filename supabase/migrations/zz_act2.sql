select calls::text a, round(total_exec_time)::text b, shared_blks_read::text c, shared_blks_written::text d, left(regexp_replace(query,'\s+',' ','g'),150) e
from pg_stat_statements order by total_exec_time desc limit 8;
