-- Disk IO fix: the site used to fetch billing data in pages of 1000 rows, and every page re-ran the whole query.
-- These return one date window as a single JSON value (one run per window). The old functions stay as they are.
create or replace function billing_rows_win(since timestamptz, until timestamptz default null)
returns jsonb language sql stable security definer set search_path = public as $$
  select case when (select app_has_page('billing') or app_is_owner()) then coalesce((
    select jsonb_agg(to_jsonb(t) order by t.delivered_at desc, t.order_id) from (
      select d.order_id, d.delivered_at, c.agency, c.agency_ref, c.name,
             coalesce(nullif(d.snap->>'base',''), c.base::text) as base,
             coalesce(nullif(d.snap->>'food',''), c.food::text) as food,
             coalesce(round(nullif(d.snap->>'hh','')::numeric)::int, c.hh) as hh,
             coalesce(round(nullif(d.snap->>'boxes','')::numeric)::int, 0) as boxes,
             coalesce(d.snap->>'letters','') as letters, d.receipt_url, d.photo_urls
      from deliveries d join customers c on c.id = d.customer_id
      where d.delivered_at is not null and d.delivered_at >= since and (until is null or d.delivered_at < until)) t
  ), '[]'::jsonb) else '[]'::jsonb end
$$;
grant execute on function billing_rows_win(timestamptz, timestamptz) to authenticated;

create or replace function billing_import_win(since date, until date default null)
returns jsonb language sql stable security definer set search_path = public as $$
  select case when (select app_has_page('billing') or app_is_owner()) then coalesce((
    select jsonb_agg(to_jsonb(r) order by r.tab_date desc, r.company, r.rowno) from (
      with newest as (
        select x.tab_date, x.company, max(x.batch) as batch from billing_import x
        where x.tab_date >= since and (until is null or x.tab_date < until) group by x.tab_date, x.company)
      select b.tab_date, b.company, b.rowno, b.ref, b.name, b.base, b.food, b.hh, b.links, b.enh
      from billing_import b join newest n on n.tab_date = b.tab_date and n.company = b.company and n.batch = b.batch) r
  ), '[]'::jsonb) else '[]'::jsonb end
$$;
grant execute on function billing_import_win(date, date) to authenticated;
