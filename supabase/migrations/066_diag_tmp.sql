select json_build_object(
 'cols',(select json_agg(column_name||':'||data_type) from information_schema.columns where table_name='change_requests' and table_schema='public'),
 'policies',(select json_agg(polname||' '||polcmd||' '||pg_get_expr(polqual,polrelid)) from pg_policy where polrelid='public.change_requests'::regclass),
 'status',(select json_agg(x) from (select status,count(*) n from change_requests group by 1) x),
 'sample_ew',(select json_agg(effective_week) from (select distinct effective_week from change_requests limit 6) z)) r;
