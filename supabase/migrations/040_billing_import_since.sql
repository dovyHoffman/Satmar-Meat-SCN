-- Billing only shows the newest weeks, so it asks for the imported sheet weeks since a date instead of all history.
create or replace function billing_import_rows_since(since date)
returns table(tab_date date, company text, rowno int, ref text, name text, base text, food text, hh int, links text[], enh int)
language sql stable security definer set search_path = public as $$
  with newest as (
    select x.tab_date, x.company, max(x.batch) as batch from billing_import x where x.tab_date >= since group by x.tab_date, x.company
  )
  select b.tab_date, b.company, b.rowno, b.ref, b.name, b.base, b.food, b.hh, b.links, b.enh
  from billing_import b
  join newest n on n.tab_date = b.tab_date and n.company = b.company and n.batch = b.batch
  where b.tab_date >= since and (select app_has_page('billing') or app_is_owner())
  order by b.tab_date desc, b.company, b.rowno
$$;
grant execute on function billing_import_rows_since(date) to authenticated;
