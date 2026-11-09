-- Same results as before. The permission check now runs once per query instead of once per row.
create or replace function billing_rows()
returns table(order_id text, delivered_at timestamptz, agency text, agency_ref text, name text, base text, food text,
              hh int, boxes int, letters text, receipt_url text, photo_urls text[])
language sql stable security definer set search_path = public as $$
  select d.order_id, d.delivered_at, c.agency, c.agency_ref, c.name,
         coalesce(nullif(d.snap->>'base',''), c.base::text),
         coalesce(nullif(d.snap->>'food',''), c.food::text),
         coalesce(round(nullif(d.snap->>'hh','')::numeric)::int, c.hh),
         coalesce(round(nullif(d.snap->>'boxes','')::numeric)::int, 0),
         coalesce(d.snap->>'letters',''), d.receipt_url, d.photo_urls
  from deliveries d join customers c on c.id = d.customer_id
  where d.delivered_at is not null and (select app_has_page('billing') or app_is_owner())
  order by d.delivered_at desc, d.order_id
$$;
grant execute on function billing_rows() to authenticated;

create or replace function billing_import_rows()
returns table(tab_date date, company text, rowno int, ref text, name text, base text, food text, hh int, links text[], enh int)
language sql stable security definer set search_path = public as $$
  with newest as (
    select x.tab_date, x.company, max(x.batch) as batch from billing_import x group by x.tab_date, x.company
  )
  select b.tab_date, b.company, b.rowno, b.ref, b.name, b.base, b.food, b.hh, b.links, b.enh
  from billing_import b
  join newest n on n.tab_date = b.tab_date and n.company = b.company and n.batch = b.batch
  where (select app_has_page('billing') or app_is_owner())
  order by b.tab_date desc, b.company, b.rowno
$$;
grant execute on function billing_import_rows() to authenticated;
