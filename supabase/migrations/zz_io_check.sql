select 'Q' k, calls::text a, round(total_exec_time)::text b, shared_blks_read::text c, shared_blks_written::text d, left(regexp_replace(query,'\s+',' ','g'),110) e
from pg_stat_statements order by (shared_blks_read+shared_blks_written+shared_blks_dirtied) desc limit 12;
