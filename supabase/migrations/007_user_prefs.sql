-- Each person's own table settings (which columns, sort order). Saved per user.
alter table profiles add column if not exists prefs jsonb not null default '{}'::jsonb;

-- A person can only ever change their OWN prefs, nothing else on the profile.
create or replace function save_my_prefs(p jsonb) returns void
language sql security definer set search_path = public as $$
  update profiles set prefs = coalesce(p,'{}'::jsonb) where id = auth.uid();
$$;
grant execute on function save_my_prefs(jsonb) to authenticated;
