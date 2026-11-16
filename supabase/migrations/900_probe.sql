select json_build_object(
 'profiles',(select json_agg(json_build_object('n',name,'r',role::text,'p',pages)) from profiles),
 'pol',(select json_agg(json_build_object('t',tablename,'n',policyname,'c',cmd,'q',qual,'w',with_check)) from pg_policies where tablename in ('change_requests')),
 'rls',(select relrowsecurity from pg_class where relname='change_requests'),
 'trg',(select json_agg(tgname) from pg_trigger where tgrelid='change_requests'::regclass and not tgisinternal)
) as r;
