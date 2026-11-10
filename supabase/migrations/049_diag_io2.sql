-- READ ONLY diagnostic
(select 'time' as k, left(regexp_replace(query,'\s+',' ','g'),90) as q, calls::text as a, round(total_exec_time::numeric/1000)::text as b, (wal_bytes/1048576)::text as c from pg_stat_statements order by total_exec_time desc limit 8)
union all
(select 'wal', left(regexp_replace(query,'\s+',' ','g'),90), calls::text, round(total_exec_time::numeric/1000)::text, (wal_bytes/1048576)::text from pg_stat_statements order by wal_bytes desc limit 6)
union all
(select 'table', relname, n_live_tup::text, pg_size_pretty(pg_total_relation_size(relid)), (n_tup_ins+n_tup_upd)::text from pg_stat_user_tables order by pg_total_relation_size(relid) desc limit 8);
