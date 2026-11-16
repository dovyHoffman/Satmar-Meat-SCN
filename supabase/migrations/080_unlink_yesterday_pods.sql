create table if not exists bk_20261116_deliveries_nov15 as
  select * from deliveries where coalesce(delivered_at, synced_at) >= '2026-11-15 05:00:00+00' and coalesce(delivered_at, synced_at) < '2026-11-16 05:00:00+00';
with u as (
  update deliveries set customer_id = null
   where coalesce(delivered_at, synced_at) >= '2026-11-15 05:00:00+00' and coalesce(delivered_at, synced_at) < '2026-11-16 05:00:00+00' and customer_id is not null
  returning 1)
select json_build_object('backup_rows',(select count(*) from bk_20261116_deliveries_nov15),'unlinked',(select count(*) from u)) as r;
