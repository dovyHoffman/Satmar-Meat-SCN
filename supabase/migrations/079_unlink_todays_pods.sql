-- backup, then unlink every delivery from today (Nov 16 New York time) so the sync can rebuild it from the uploaded export only
create table if not exists bk_20261116_deliveries as
  select * from deliveries where coalesce(delivered_at, synced_at) >= '2026-11-16 05:00:00+00';
with u as (
  update deliveries set customer_id = null
   where coalesce(delivered_at, synced_at) >= '2026-11-16 05:00:00+00' and customer_id is not null
  returning 1)
select json_build_object('backup_rows',(select count(*) from bk_20261116_deliveries),'unlinked',(select count(*) from u)) as r;
