-- Run this one (includes 004 and 005, safe to run twice).
alter table customers add column if not exists legal_address text not null default '';
alter table customers add column if not exists cell text not null default '';
alter table customers add column if not exists email text not null default '';
alter table customers add column if not exists notes_labels text not null default '';
alter table customers add column if not exists note2 text not null default '';

-- Fills ONLY empty fields. Never overwrites. Owner only.
create or replace function fill_legal_addresses(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'owner only'; end if;
  update customers c set
    legal_address = case when c.legal_address='' then coalesce(x.legal,'') else c.legal_address end,
    cell          = case when c.cell=''          then coalesce(x.cell,'')  else c.cell end,
    email         = case when c.email=''         then coalesce(x.email,'') else c.email end,
    notes_labels  = case when c.notes_labels=''  then coalesce(x.nl,'')    else c.notes_labels end,
    note2         = case when c.note2=''         then coalesce(x.n2,'')    else c.note2 end
  from jsonb_to_recordset(p) as x(agency text, ref text, legal text, cell text, email text, nl text, n2 text)
  where c.agency = x.agency
    and c.id_norm = lower(regexp_replace(x.ref,'[\s\-]+','','g'));
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function fill_legal_addresses(jsonb) to authenticated;
