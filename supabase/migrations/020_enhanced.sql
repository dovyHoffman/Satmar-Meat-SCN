-- Third kind of billing: "Enhanced" members of a raw box are billed at their own price (household size 0 in agency_hh_prices).
-- Box customers: regular HH billed by the household-size list, Enhanced billed per person at the enhanced price.
alter table billing_import add column if not exists enh int not null default 0;
alter table agency_hh_prices drop constraint if exists agency_hh_prices_hh_check;
alter table agency_hh_prices add constraint agency_hh_prices_hh_check check (hh between 0 and 10);
insert into agency_hh_prices (agency, hh, price) values ('LT',0,100) on conflict (agency, hh) do nothing;

create or replace function save_billing_import(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'not allowed'; end if;
  insert into billing_import (tab_date, company, rowno, batch, ref, name, base, food, hh, enh, links)
  select (x->>'d')::date, x->>'c', (x->>'r')::int, x->>'b', coalesce(x->>'i',''), coalesce(x->>'n',''),
         case when x->>'k' = 'box' then 'box' else 'meals' end, coalesce(x->>'f',''),
         greatest(1, coalesce((x->>'h')::numeric,1)::int),
         greatest(0, coalesce((x->>'e')::numeric,0)::int),
         coalesce((select array_agg(l) from jsonb_array_elements_text(coalesce(x->'l','[]'::jsonb)) l), '{}')
  from jsonb_array_elements(p) x
  on conflict (tab_date, company, rowno, batch) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on function save_billing_import(jsonb) to authenticated;

drop function if exists billing_import_rows();
create or replace function billing_import_rows()
returns table(tab_date date, company text, rowno int, ref text, name text, base text, food text, hh int, links text[], enh int)
language sql stable security definer set search_path = public as $$
  with newest as (
    select x.tab_date, x.company, max(x.batch) as batch from billing_import x group by x.tab_date, x.company
  )
  select b.tab_date, b.company, b.rowno, b.ref, b.name, b.base, b.food, b.hh, b.links, b.enh
  from billing_import b
  join newest n on n.tab_date = b.tab_date and n.company = b.company and n.batch = b.batch
  where (app_has_page('billing') or app_is_owner())
  order by b.tab_date desc, b.company, b.rowno
$$;
grant execute on function billing_import_rows() to authenticated;
