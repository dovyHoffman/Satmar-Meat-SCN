-- office staff (secretary/manager/admin) must be able to enter changes for next week
update public.profiles
   set pages = array_append(coalesce(pages,'{}'), 'changes')
 where role::text in ('secretary','manager','admin')
   and not ('changes' = any(coalesce(pages,'{}')));
select json_build_object('profiles',(select json_agg(json_build_object('n',name,'r',role::text,'p',pages)) from profiles)) as r;
