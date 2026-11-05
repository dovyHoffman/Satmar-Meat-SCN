-- Mother's CIN, needed in the delivery file (#cin column). Never shown on the customer list; fills empty values only.
alter table customers add column if not exists cin text not null default '';
create or replace function fill_cin(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'owner only'; end if;
  update customers c set cin = coalesce(x.cin,'')
  from jsonb_to_recordset(p) as x(agency text, ref text, cin text)
  where c.cin = '' and coalesce(x.cin,'') <> ''
    and c.agency = x.agency
    and c.id_norm = lower(regexp_replace(x.ref,'[\s\-]+','','g'));
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function fill_cin(jsonb) to authenticated;
