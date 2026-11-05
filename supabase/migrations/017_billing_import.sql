-- Billing weeks read from the company tabs of the Billing SCN 82 sheet (UJO 1027, LH 1027 ...).
-- One line per sheet row: the customer ID, food type, household and the proof-of-delivery links.
-- Nothing is deleted. Uploading the same week again adds a newer batch; the newest batch of a
-- (week, company) is the one used. Names and phones are NOT stored, only what billing needs.
create table if not exists billing_import (
  tab_date date not null,                 -- date of the sheet tab (the Tuesday, e.g. 2026-10-27)
  company text not null,
  rowno int not null,
  batch text not null,                    -- yyyymmddhh24miss of the upload
  ref text not null default '',           -- Application ID / Family ID as written in the sheet
  name text not null default '',
  base text not null default 'meals',     -- 'box' or 'meals'
  food text not null default '',
  hh int not null default 1,
  links text[] not null default '{}',     -- proof of delivery links
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (tab_date, company, rowno, batch)
);
alter table billing_import enable row level security;
-- no policies: only the two functions below touch this table.
drop trigger if exists nd_billing_import on billing_import;
create trigger nd_billing_import before delete on billing_import for each row execute function no_delete();

create or replace function save_billing_import(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'not allowed'; end if;
  insert into billing_import (tab_date, company, rowno, batch, ref, name, base, food, hh, links)
  select (x->>'d')::date, x->>'c', (x->>'r')::int, x->>'b', coalesce(x->>'i',''), coalesce(x->>'n',''),
         case when x->>'k' = 'box' then 'box' else 'meals' end, coalesce(x->>'f',''),
         greatest(1, coalesce((x->>'h')::numeric,1)::int),
         coalesce((select array_agg(l) from jsonb_array_elements_text(coalesce(x->'l','[]'::jsonb)) l), '{}')
  from jsonb_array_elements(p) x
  on conflict (tab_date, company, rowno, batch) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function save_billing_import(jsonb) to authenticated;

create or replace function billing_import_rows()
returns table(tab_date date, company text, rowno int, ref text, name text, base text, food text, hh int, links text[])
language sql stable security definer set search_path = public as $$
  select b.tab_date, b.company, b.rowno, b.ref, b.name, b.base, b.food, b.hh, b.links
  from billing_import b
  where (app_has_page('billing') or app_is_owner())
    and b.batch = (select max(x.batch) from billing_import x where x.tab_date = b.tab_date and x.company = b.company)
  order by b.tab_date desc, b.company, b.rowno
$$;
grant execute on function billing_import_rows() to authenticated;
