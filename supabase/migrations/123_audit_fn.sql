-- READ ONLY. How audit_log.user_name is filled, and the account names that did changes in the last 2 days (counts only).
select (select left(string_agg(p.prosrc, E'\n----\n'), 1800) from pg_proc p where p.prosrc ilike '%insert into audit_log%') fn_source,
 (select coalesce(json_agg(json_build_object('user',user_name,'n',n)),'[]'::json) from (select user_name, count(*) n from audit_log where at > now() - interval '2 days' group by 1 order by 2 desc limit 8) t) recent_users,
 (select coalesce(json_agg(json_build_object('name',name,'role',role)),'[]'::json) from profiles where name ilike '%assistant%' or name ilike 'AI%') ai_profiles;
