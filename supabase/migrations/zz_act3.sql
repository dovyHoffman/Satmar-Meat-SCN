select 'ACT' k, count(*)::text a, round(max(extract(epoch from now()-query_start)))::text b, left(regexp_replace(query,'\s+',' ','g'),330) c from pg_stat_activity where datname=current_database() and state='active' and pid<>pg_backend_pid() and usename not in ('supabase_admin','supabase_auth_admin','supabase_storage_admin') group by 4
union all
select 'TOP', calls::text, round(total_exec_time)::text, left(regexp_replace(query,'\s+',' ','g'),330) from (select * from pg_stat_statements order by total_exec_time desc limit 6) s;
