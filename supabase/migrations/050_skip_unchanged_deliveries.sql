-- The Scanovator sync re-saves every delivery each time with a new synced_at, so each run rewrites thousands of unchanged rows
-- (about 308,000 writes for 9,600 deliveries). Skip an update when nothing but synced_at would change. Data is unchanged.
create or replace function skip_unchanged_delivery() returns trigger
language plpgsql as $$
begin
  if (to_jsonb(new) - 'synced_at') = (to_jsonb(old) - 'synced_at') then
    return null;
  end if;
  return new;
end $$;
drop trigger if exists a_skip_unchanged_delivery on deliveries;
create trigger a_skip_unchanged_delivery before update on deliveries for each row execute function skip_unchanged_delivery();
