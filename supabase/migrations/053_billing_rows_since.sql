-- Same as billing_rows() but only deliveries on/after a date, so the site can keep older weeks saved on the device.
create or replace function billing_rows_since(since timestamptz)
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
  where d.delivered_at is not null and d.delivered_at >= since and (select app_has_page('billing') or app_is_owner())
  order by d.delivered_at desc, d.order_id
$$;
grant execute on function billing_rows_since(timestamptz) to authenticated;
