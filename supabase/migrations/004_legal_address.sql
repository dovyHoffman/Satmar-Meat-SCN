-- Legal address (from the Customer_data list). Shown on the customer card.
alter table customers add column if not exists legal_address text not null default '';

-- Fills ONLY empty legal addresses; never overwrites one that is already there. Owner only.
create or replace function fill_legal_addresses(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'owner only'; end if;
  update customers c set legal_address = x.legal
  from jsonb_to_recordset(p) as x(agency text, ref text, legal text)
  where c.agency = x.agency
    and c.id_norm = lower(regexp_replace(x.ref,'[\s\-]+','','g'))
    and c.legal_address = '' and coalesce(x.legal,'') <> '';
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function fill_legal_addresses(jsonb) to authenticated;
