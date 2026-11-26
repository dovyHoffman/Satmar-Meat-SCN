select count(*)::text a, state b, coalesce(wait_event,'-') c, left(regexp_replace(query,'\s+',' ','g'),110) d, round(max(extract(epoch from now()-query_start)))::text e
from pg_stat_activity where datname=current_database() and pid<>pg_backend_pid() and usename not in ('supabase_admin','supabase_auth_admin','supabase_storage_admin') group by 2,3,4 order by 1 desc limit 15;
