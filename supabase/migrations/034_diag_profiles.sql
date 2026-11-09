select 'trigger' k, tgrelid::regclass::text t, tgname n, pg_get_triggerdef(oid) d from pg_trigger where not tgisinternal and tgrelid in ('public.profiles'::regclass)
union all
select 'fk', conrelid::regclass::text, conname, pg_get_constraintdef(oid) from pg_constraint where contype='f' and confrelid in ('auth.users'::regclass,'public.profiles'::regclass)
union all
select 'authtrigger', tgrelid::regclass::text, tgname, pg_get_triggerdef(oid) from pg_trigger where not tgisinternal and tgrelid='auth.users'::regclass;
