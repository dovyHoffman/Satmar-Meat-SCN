select calls::text a, round(total_exec_time)::text b, regexp_replace(query,'\s+',' ','g') e
from pg_stat_statements where query like '%pgrst_call%' order by total_exec_time desc limit 2;
