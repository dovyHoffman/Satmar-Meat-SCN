-- Owner uploads the D-box (Williamsburg) delivery report; each row becomes a delivery with its picture.
create or replace function save_dbox_pods(p jsonb) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not app_is_owner() then raise exception 'not allowed'; end if;
  insert into deliveries (order_id, customer_id, week_label, driver, delivered_at, receipt_url, photo_urls, photo_paths, synced_at, snap)
  select x->>'o', (x->>'c')::uuid, coalesce(x->>'w',''), coalesce(x->>'d',''), (x->>'t')::timestamptz, '',
         coalesce((select array_agg(v) from jsonb_array_elements_text(x->'p') v), '{}'::text[]), '{}'::text[], now(), x->'s'
  from jsonb_array_elements(p) x
  where coalesce(x->>'o','') <> '' and coalesce(x->>'c','') <> ''
  on conflict (order_id) do update
    set customer_id = excluded.customer_id, week_label = excluded.week_label, driver = excluded.driver,
        delivered_at = excluded.delivered_at, photo_urls = excluded.photo_urls, synced_at = now(), snap = excluded.snap;
  get diagnostics n = row_count;
  return n;
end $$;
