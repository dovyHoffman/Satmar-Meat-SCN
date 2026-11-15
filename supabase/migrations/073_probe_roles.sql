select 'col' k, data_type d, udt_name u from information_schema.columns where table_name='profiles' and column_name='role'
union all select 'chk', conname, pg_get_constraintdef(oid) from pg_constraint where conrelid='profiles'::regclass and contype='c'
union all select 'roles', role::text, count(*)::text from profiles group by role
union all select 'fn', proname, left(prosrc,300) from pg_proc where proname in ('app_is_owner','app_has_page');
