-- CCS 11/14 billing: FAM-1645 (Box, household 2) is on the owner's CCS list but was not in the sheet import. Add it to the latest CCS import of that week.
insert into billing_import (tab_date, company, rowno, batch, ref, name, base, food, hh, enh, links)
select '2026-11-10', 'CCS', (select max(rowno)+1 from billing_import where tab_date='2026-11-10' and company='CCS' and batch=b.batch), b.batch,
       'FAM-1645', c.name, 'box', 'raw', 2, 0, '{}'
from (select max(batch) batch from billing_import where tab_date='2026-11-10' and company='CCS') b,
     (select name from customers where agency='CCS' and agency_ref='FAM-1645' limit 1) c
where not exists (select 1 from billing_import x where x.tab_date='2026-11-10' and x.company='CCS' and x.ref='FAM-1645' and x.batch=b.batch);
select count(*) rows_, sum(case when ref='FAM-1645' then 1 else 0 end) has_1645 from billing_import
where tab_date='2026-11-10' and company='CCS' and batch=(select max(batch) from billing_import where tab_date='2026-11-10' and company='CCS');
