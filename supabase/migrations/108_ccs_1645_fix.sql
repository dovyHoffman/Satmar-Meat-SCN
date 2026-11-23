-- Fix of 107: FAM-1645 was added to the wrong week (the 11/7 sheet import). The 11/14 week bills the saved list (billing_snap).
-- 1) put the 11/7 CCS import back as it was: a new latest batch = the previous batch without that row (nothing deleted; the older batch stays).
insert into billing_import (tab_date, company, rowno, batch, ref, name, base, food, hh, enh, links)
select tab_date, company, rowno, to_char(now() at time zone 'utc','YYYYMMDD24HH24MISS'), ref, name, base, food, hh, enh, links
from billing_import where tab_date='2026-11-10' and company='CCS'
  and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='CCS') and ref<>'FAM-1645';
-- 2) add FAM-1645 to the saved 11/14 CCS list
insert into billing_snap (week, agency, agency_ref, name, base, food, hh, enh)
select '2026-11-14','CCS','FAM-1645', c.name, 'box', 'raw', 2, 0
from customers c where c.agency='CCS' and c.agency_ref='FAM-1645'
on conflict do nothing;
select (select count(*) from billing_import where tab_date='2026-11-10' and company='CCS' and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='CCS')) import_rows_now,
 (select count(*) from billing_import where tab_date='2026-11-10' and company='CCS' and ref='FAM-1645' and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='CCS')) has_1645_import,
 (select count(*) from billing_snap where week='2026-11-14' and agency='CCS') snap_rows;
