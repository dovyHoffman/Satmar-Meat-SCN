-- Let the owner REMOVE a person (done by the server function, which deletes the login; the access row goes with it).
-- A signed-in person still cannot delete profile rows directly from the website: those deletes stay blocked.
drop trigger if exists nd_profiles on profiles;
create or replace function profiles_guard_delete() returns trigger language plpgsql as $$
begin
  if auth.uid() is not null then
    raise exception 'People cannot be deleted from the website directly. Use Remove in Settings.';
  end if;
  return old;
end $$;
create trigger nd_profiles before delete on profiles for each row execute function profiles_guard_delete();
