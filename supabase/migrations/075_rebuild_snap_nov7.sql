-- The saved copy of last week (week of 11/9, key 2026-11-07) was taken after the new list was applied.
-- Rebuild it from the safety copy made right before the approval (bk_20261114b_customers).
alter table billing_snap disable trigger nd_billing_snap;
delete from billing_snap where week = '2026-11-07';
alter table billing_snap enable trigger nd_billing_snap;
insert into billing_snap (week, agency, agency_ref, name, base, food, hh, enh)
select '2026-11-07', agency, agency_ref, name, base, food, hh, coalesce(enh, 0)
from bk_20261114b_customers
where active
on conflict do nothing;
select 'snap_rows' k, count(*)::text v from billing_snap where week = '2026-11-07'
union all select 'bk_active', count(*)::text from bk_20261114b_customers where active;
