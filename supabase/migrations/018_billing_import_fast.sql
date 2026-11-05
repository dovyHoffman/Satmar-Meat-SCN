-- The first version of billing_import_rows() looked up the newest batch once per row, which is too slow
-- for tens of thousands of lines. Same result, computed once per (week, company).
create index if not exists billing_import_wk on billing_import (tab_date, company, batch);
create or replace function billing_import_rows()
returns table(tab_date date, company text, rowno int, ref text, name text, base text, food text, hh int, links text[])
language sql stable security definer set search_path = public as $$
  with newest as (
    select x.tab_date, x.company, max(x.batch) as batch from billing_import x group by x.tab_date, x.company
  )
  select b.tab_date, b.company, b.rowno, b.ref, b.name, b.base, b.food, b.hh, b.links
  from billing_import b
  join newest n on n.tab_date = b.tab_date and n.company = b.company and n.batch = b.batch
  where (app_has_page('billing') or app_is_owner())
  order by b.tab_date desc, b.company, b.rowno
$$;
grant execute on function billing_import_rows() to authenticated;
